import { useDeferredValue, useMemo, useState } from 'react';
import { FeedbackBanner } from './FeedbackBanner';
import { MasterRecordFormDialog } from './MasterRecordFormDialog';
import { ConfirmDialog } from './ConfirmDialog';
import { PanelCard } from './PanelCard';
import { useMasterCrud } from '../hooks/useMasterCrud';
import { ActionMenu } from './ActionMenu';
import { formatDateTime } from '../utils/format';


export function MasterCrudPage({ config, model, service }) {
  const [search, setSearch] = useState('');
  const [editingRecord, setEditingRecord] = useState(null);
  const [recordPendingDelete, setRecordPendingDelete] = useState(null);
  const [formOpen, setFormOpen] = useState(false);
  const deferredSearch = useDeferredValue(search);

  const {
    records,
    loading,
    error,
    actionError,
    successMessage,
    isSaving,
    deletingId,
    clearFeedback,
    createRecord,
    updateRecord,
    deleteRecord,
  } = useMasterCrud({
    service,
    singularLabel: config.singularLabel,
  });
  
  const [filter, setFilter] = useState('all');


  const filteredRecords = useMemo(() => {
    const normalizedSearch = deferredSearch.toLowerCase().trim();

    return records.filter((record) => {
      const matchesSearch = !normalizedSearch || model.getSearchText(record).includes(normalizedSearch);
      const matchesFilter = !config.filterField || filter === 'all' || record[config.filterField] === filter;
      return matchesSearch && matchesFilter;
    });
  }, [deferredSearch, model, records, filter, config.filterField]);


  const formInitialValues = editingRecord
    ? { ...model.getEmptyValues(), ...editingRecord }
    : model.getEmptyValues();

  async function handleSave(values) {
    const draft = model.createDraft(values);
    const didSave = editingRecord
      ? await updateRecord(editingRecord.id, draft)
      : await createRecord(draft);

    if (didSave) {
      setFormOpen(false);
      setEditingRecord(null);
    }

    return didSave;
  }

  async function handleDelete() {
    if (!recordPendingDelete) {
      return;
    }

    const didDelete = await deleteRecord(recordPendingDelete.id);
    if (didDelete) {
      setRecordPendingDelete(null);
    }
  }

  function openCreateDialog() {
    clearFeedback();
    setEditingRecord(null);
    setFormOpen(true);
  }

  function openEditDialog(record) {
    clearFeedback();
    setEditingRecord(record);
    setFormOpen(true);
  }

  function closeFormDialog() {
    if (isSaving) {
      return;
    }

    setFormOpen(false);
    setEditingRecord(null);
  }

  function closeDeleteDialog() {
    if (deletingId) {
      return;
    }

    setRecordPendingDelete(null);
  }

  const deletingLabel = recordPendingDelete ? model.getRecordLabel(recordPendingDelete) : '';
  const liveToneClass =
    loading || error ? 'dot-firebase-partial' : 'dot-firebase';
  const liveStatusMessage = error
    ? `Firestore connection needs attention for ${config.collectionName}.`
    : loading
      ? config.loadingMessage
      : config.liveMessage;

  return (
    <div className="page-stack">
      <PanelCard
        title={config.title}
        subtitle={config.subtitle}
        actions={
          <button type="button" className="primary-button" onClick={openCreateDialog}>
            {config.createButtonLabel}
          </button>
        }
      >
        <div className="live-note">
          <span className={`dot ${liveToneClass}`} />
          {liveStatusMessage}
        </div>

        <FeedbackBanner tone="error">{error}</FeedbackBanner>
        <FeedbackBanner tone="error">{actionError}</FeedbackBanner>
        <FeedbackBanner tone="success">{successMessage}</FeedbackBanner>

        <div className="toolbar listing-toolbar">
          <label className="listing-search-field">
            <span>Search {config.pluralLabel}</span>
            <input
              className="search-input"
              type="search"
              value={search}
              onChange={(event) => setSearch(event.target.value)}
              placeholder={config.searchPlaceholder}
            />
          </label>
          {config.filterOptions && (
            <label className="listing-status-filter">
              <span>{config.filterLabel || 'Filter'}</span>
              <select
                value={filter}
                onChange={(event) => setFilter(event.target.value)}
              >
                <option value="all">All {config.pluralLabel}</option>
                {config.filterOptions.map((opt) => (
                  <option key={opt.value} value={opt.value}>
                    {opt.label}
                  </option>
                ))}
              </select>
            </label>
          )}
          <div className="listing-toolbar-note">
            <strong>{filteredRecords.length}</strong>
            <span>{filteredRecords.length === 1 ? `${config.singularLabel} visible` : `${config.pluralLabel} visible`}</span>
          </div>
        </div>


        <div className={`table-wrap ${config.tableWrapClassName || ''}`}>
          <table className={`data-table ${config.tableClassName || ''}`}>

            <thead>
              <tr>
                {config.columns.map((column) => (
                  <th key={column.header}>{column.header}</th>
                ))}
                {!config.hideUpdatedColumn && <th>Updated</th>}
                <th>Actions</th>

              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan={config.columns.length + 2}>
                    <div className="empty-state">{config.loadingMessage}</div>
                  </td>
                </tr>
              ) : filteredRecords.length > 0 ? (
                filteredRecords.map((record) => (
                  <tr key={record.id}>
                    {config.columns.map((column) => (
                      <td key={`${record.id}-${column.header}`} className={column.className}>
                        {column.renderCell(record)}
                      </td>
                    ))}
                    {!config.hideUpdatedColumn && (
                      <td className="users-activity-cell">
                        <small>{formatDateTime(record.updatedAt ?? record.createdAt)}</small>
                      </td>
                    )}
                    <td className="table-actions-cell">

                      <ActionMenu
                        label={`Manage ${model.getRecordLabel(record)}`}
                        iconOnly
                        items={[
                          {
                            key: 'edit',
                            label: 'Edit',
                            icon: 'edit',
                            onSelect: () => openEditDialog(record),
                          },
                          {
                            key: 'delete',
                            label: 'Delete',
                            icon: 'delete',
                            tone: 'danger',
                            onSelect: () => {
                              clearFeedback();
                              setRecordPendingDelete(record);
                            },
                          },
                        ]}
                      />
                    </td>

                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={config.columns.length + 2}>
                    <div className="empty-state">
                      {search
                        ? `No ${config.pluralLabel} matched your search.`
                        : config.emptyStateMessage}
                    </div>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </PanelCard>

      <MasterRecordFormDialog
        open={formOpen}
        title={editingRecord ? config.editDialogTitle : config.createDialogTitle}
        subtitle={config.formSubtitle}
        fields={config.fields}
        initialValues={formInitialValues}
        validate={model.validate}
        isSaving={isSaving}
        submitError={actionError}
        onClose={closeFormDialog}
        onSubmit={handleSave}
      />

      <ConfirmDialog
        open={Boolean(recordPendingDelete)}
        title={config.deleteDialogTitle}
        message={`Delete "${deletingLabel}" from ${config.collectionName}? This action cannot be undone.`}
        confirmLabel="Delete record"
        busyLabel="Deleting..."
        busy={deletingId === recordPendingDelete?.id}
        onConfirm={handleDelete}
        onClose={closeDeleteDialog}
      />
    </div>
  );
}
