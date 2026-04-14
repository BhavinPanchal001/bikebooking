import { useDeferredValue, useMemo, useState } from 'react';
import { FeedbackBanner } from './FeedbackBanner';
import { MasterRecordFormDialog } from './MasterRecordFormDialog';
import { ConfirmDialog } from './ConfirmDialog';
import { PanelCard } from './PanelCard';
import { useMasterCrud } from '../hooks/useMasterCrud';
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

  const filteredRecords = useMemo(() => {
    const normalizedSearch = deferredSearch.toLowerCase().trim();

    return records.filter((record) => {
      if (!normalizedSearch) {
        return true;
      }

      return model.getSearchText(record).includes(normalizedSearch);
    });
  }, [deferredSearch, model, records]);

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
          <span className="dot dot-firebase" />
          {loading ? config.loadingMessage : config.liveMessage}
        </div>

        <FeedbackBanner tone="error">{error}</FeedbackBanner>
        <FeedbackBanner tone="error">{actionError}</FeedbackBanner>
        <FeedbackBanner tone="success">{successMessage}</FeedbackBanner>

        <div className="toolbar">
          <input
            className="search-input"
            type="search"
            value={search}
            onChange={(event) => setSearch(event.target.value)}
            placeholder={config.searchPlaceholder}
          />
          <div className="toolbar-note">
            {filteredRecords.length} {config.pluralLabel} visible
          </div>
        </div>

        <div className="table-wrap">
          <table className="data-table">
            <thead>
              <tr>
                {config.columns.map((column) => (
                  <th key={column.header}>{column.header}</th>
                ))}
                <th>Updated</th>
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
                    <td>{formatDateTime(record.updatedAt ?? record.createdAt)}</td>
                    <td className="table-actions-cell">
                      <div className="row-actions">
                        <button
                          type="button"
                          className="secondary-button"
                          onClick={() => openEditDialog(record)}
                        >
                          Edit
                        </button>
                        <button
                          type="button"
                          className="danger-button danger-button-soft"
                          onClick={() => {
                            clearFeedback();
                            setRecordPendingDelete(record);
                          }}
                        >
                          Delete
                        </button>
                      </div>
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
