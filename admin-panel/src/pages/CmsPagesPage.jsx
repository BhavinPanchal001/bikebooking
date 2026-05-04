import { useDeferredValue, useEffect, useMemo, useState } from 'react';
import { ActionMenu } from '../components/ActionMenu';
import { CmsPageEditorDialog } from '../components/CmsPageEditorDialog';
import { ConfirmDialog } from '../components/ConfirmDialog';
import { FeedbackBanner } from '../components/FeedbackBanner';
import { PanelCard } from '../components/PanelCard';
import { cmsPagesService } from '../services/cmsPagesService';
import { formatDateTime } from '../utils/format';

const statusFilters = [
  { value: 'all', label: 'All pages' },
  { value: 'published', label: 'Published' },
  { value: 'draft', label: 'Drafts' },
];

function getStatusLabel(record) {
  if (record.isPublished && record.hasDraftChanges) {
    return 'Published + Draft';
  }

  return record.isPublished ? 'Published' : 'Draft';
}

function getStatusClassName(record) {
  if (record.isPublished && record.hasDraftChanges) {
    return 'status-pill status-reviewing';
  }

  return `status-pill ${record.isPublished ? 'status-approved' : 'status-pending'}`;
}

export function CmsPagesPage() {
  const [pages, setPages] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [actionError, setActionError] = useState('');
  const [successMessage, setSuccessMessage] = useState('');
  const [isSaving, setIsSaving] = useState(false);
  const [busyAction, setBusyAction] = useState({ type: '', slug: '' });
  const [editorOpen, setEditorOpen] = useState(false);
  const [editingPage, setEditingPage] = useState(null);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [pendingAction, setPendingAction] = useState(null);
  const deferredSearch = useDeferredValue(search);

  useEffect(() => {
    setLoading(true);
    setError('');

    return cmsPagesService.subscribe({
      onData(nextPages) {
        setPages(nextPages);
        setLoading(false);
        setError('');
      },
      onError(message) {
        setLoading(false);
        setError(message || 'Unable to load CMS pages.');
      },
    });
  }, []);

  const filteredPages = useMemo(() => {
    const normalizedSearch = deferredSearch.toLowerCase().trim();

    return pages.filter((record) => {
      const matchesSearch =
        !normalizedSearch ||
        `${record.title} ${record.slug} ${record.previewText}`.toLowerCase().includes(normalizedSearch);

      if (!matchesSearch) {
        return false;
      }

      if (statusFilter === 'published') {
        return record.isPublished;
      }

      if (statusFilter === 'draft') {
        return !record.isPublished || record.hasDraftChanges;
      }

      return true;
    });
  }, [deferredSearch, pages, statusFilter]);

  function clearFeedback() {
    setActionError('');
    setSuccessMessage('');
  }

  function openCreateDialog() {
    clearFeedback();
    setEditingPage(null);
    setEditorOpen(true);
  }

  function openEditDialog(record) {
    clearFeedback();
    setEditingPage(record);
    setEditorOpen(true);
  }

  function closeEditorDialog() {
    if (isSaving) {
      return;
    }

    setEditorOpen(false);
    setEditingPage(null);
  }

  async function handleSave(values) {
    clearFeedback();
    setIsSaving(true);

    try {
      if (editingPage?.slug) {
        await cmsPagesService.update(editingPage.slug, {
          ...values,
          version: editingPage.version,
        });
        setSuccessMessage(`Draft saved for "${values.title}".`);
      } else {
        await cmsPagesService.create(values);
        setSuccessMessage(`Draft created for "${values.title}".`);
      }

      setEditorOpen(false);
      setEditingPage(null);
    } catch (nextError) {
      setActionError(nextError?.message || 'Unable to save this CMS page.');
    } finally {
      setIsSaving(false);
    }
  }

  async function handlePendingAction() {
    if (!pendingAction?.slug || !pendingAction?.type) {
      return;
    }

    clearFeedback();
    setBusyAction({ type: pendingAction.type, slug: pendingAction.slug });

    try {
      if (pendingAction.type === 'publish') {
        await cmsPagesService.publish(pendingAction.slug);
        setSuccessMessage(`"${pendingAction.title}" is now live in the app.`);
      } else if (pendingAction.type === 'unpublish') {
        await cmsPagesService.unpublish(pendingAction.slug);
        setSuccessMessage(`"${pendingAction.title}" has been unpublished.`);
      } else if (pendingAction.type === 'delete') {
        await cmsPagesService.remove(pendingAction.slug);
        setSuccessMessage(`"${pendingAction.title}" has been deleted.`);
      }

      setPendingAction(null);
    } catch (nextError) {
      setActionError(nextError?.message || 'Unable to complete this CMS action.');
    } finally {
      setBusyAction({ type: '', slug: '' });
    }
  }

  const liveToneClass = loading || error ? 'dot-firebase-partial' : 'dot-firebase';
  const liveStatusMessage = error
    ? 'Firestore connection needs attention for cms_pages.'
    : loading
      ? 'Loading CMS pages from Firestore...'
      : 'CMS drafts and published pages are syncing live with the Firestore cms_pages collection.';

  return (
    <div className="page-stack">
      <PanelCard
        title="CMS Pages"
        subtitle="Write once, preview it in the current mobile layout, and publish the exact version the app should read."
        actions={
          <button type="button" className="primary-button" onClick={openCreateDialog}>
            Create page
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

        <div className="toolbar cms-pages-toolbar">
          <label className="cms-pages-search-field">
            <span>Search pages</span>
            <input
              className="search-input"
              type="search"
              value={search}
              onChange={(event) => setSearch(event.target.value)}
              placeholder="Title, slug, or copy"
            />
          </label>
          <label className="cms-pages-filter-row">
            <span>Status</span>
            <select
              value={statusFilter}
              onChange={(event) => setStatusFilter(event.target.value)}
            >
              {statusFilters.map((filter) => (
                <option key={filter.value} value={filter.value}>
                  {filter.label}
                </option>
              ))}
            </select>
          </label>
          <div className="cms-pages-toolbar-note">
            <strong>{filteredPages.length}</strong>
            <span>{filteredPages.length === 1 ? 'page visible' : 'pages visible'}</span>
          </div>
        </div>

        <div className="table-wrap cms-pages-table-wrap">
          <table className="data-table cms-pages-table">
            <thead>
              <tr>
                <th>Page</th>
                <th>Status</th>
                <th>Version</th>
                <th>Publishing</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan={5}>
                    <div className="empty-state">Loading CMS pages from Firestore...</div>
                  </td>
                </tr>
              ) : filteredPages.length > 0 ? (
                filteredPages.map((record) => {
                  const isPublishing =
                    busyAction.slug === record.slug && busyAction.type === 'publish';
                  const isUnpublishing =
                    busyAction.slug === record.slug && busyAction.type === 'unpublish';
                  const isDeleting = busyAction.slug === record.slug && busyAction.type === 'delete';
                  const publishLabel = record.isPublished
                    ? record.hasDraftChanges
                      ? 'Update live'
                      : 'Republish'
                    : 'Publish';

                  return (
                    <tr key={record.slug}>
                      <td>
                        <div className="cms-page-identity">
                          <strong>{record.title}</strong>
                          <span>{record.slug}</span>
                          <span className="cms-page-preview">{record.previewText || 'No preview text yet.'}</span>
                        </div>
                      </td>
                      <td>
                        <div className="cms-status-cell">
                          <span className={getStatusClassName(record)}>{getStatusLabel(record)}</span>
                          {record.hasDraftChanges && record.publishedVersion > 0 ? (
                            <small style={{ color: 'var(--muted)', fontSize: '0.72rem' }}>
                              Draft changes pending
                            </small>
                          ) : null}
                        </div>
                      </td>
                      <td>
                        <div className="cms-page-identity">
                          <span className="cms-version-badge">Draft v{record.version}</span>
                          {record.publishedVersion > 0 && (
                            <span style={{ fontSize: '0.78rem' }}>Live v{record.publishedVersion}</span>
                          )}
                        </div>
                      </td>
                      <td>
                        <div className="cms-publish-info">
                          <strong>{record.publishedByEmail || '-'}</strong>
                          <span>{record.publishedAt ? formatDateTime(record.publishedAt) : 'Never published'}</span>
                        </div>
                      </td>
                      <td className="table-actions-cell">
                        <ActionMenu
                          label={`Manage ${record.title}`}
                          iconOnly
                          items={[
                            {
                              key: 'edit',
                              label: 'Edit draft',
                              icon: 'edit',
                              onSelect: () => openEditDialog(record),
                            },
                            {
                              key: 'publish',
                              label: publishLabel,
                              icon: 'publish',
                              disabled: isPublishing || isSaving,
                              onSelect: () =>
                                setPendingAction({
                                  type: 'publish',
                                  slug: record.slug,
                                  title: record.title,
                                }),
                            },
                            record.isPublished ? {
                              key: 'unpublish',
                              label: 'Unpublish',
                              icon: 'unpublish',
                              tone: 'danger',
                              disabled: isUnpublishing || isSaving,
                              onSelect: () =>
                                setPendingAction({
                                  type: 'unpublish',
                                  slug: record.slug,
                                  title: record.title,
                                }),
                            } : null,
                            {
                              key: 'delete',
                              label: 'Delete',
                              icon: 'delete',
                              tone: 'danger',
                              disabled: isDeleting || isSaving,
                              onSelect: () =>
                                setPendingAction({
                                  type: 'delete',
                                  slug: record.slug,
                                  title: record.title,
                                }),
                            },
                          ]}
                        />
                      </td>
                    </tr>
                  );
                })
              ) : (
                <tr>
                  <td colSpan={5}>
                    <div className="empty-state">
                      {search || statusFilter !== 'all'
                        ? 'No CMS pages matched the current filters.'
                        : 'No CMS pages have been created yet.'}
                    </div>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </PanelCard>

      <CmsPageEditorDialog
        open={editorOpen}
        initialValues={editingPage ?? undefined}
        isSaving={isSaving}
        submitError={actionError}
        onClose={closeEditorDialog}
        onSubmit={handleSave}
      />

      <ConfirmDialog
        open={Boolean(pendingAction)}
        title={
          pendingAction?.type === 'publish'
            ? 'Publish CMS page'
            : pendingAction?.type === 'unpublish'
              ? 'Unpublish CMS page'
              : 'Delete CMS page'
        }
        message={
          pendingAction?.type === 'publish'
            ? `Publish "${pendingAction?.title}" so the mobile app starts using the latest draft?`
            : pendingAction?.type === 'unpublish'
              ? `Unpublish "${pendingAction?.title}" so the mobile app falls back to its bundled copy?`
              : `Delete "${pendingAction?.title}" from cms_pages? This will also remove its version snapshots.`
        }
        confirmLabel={
          pendingAction?.type === 'publish'
            ? 'Publish now'
            : pendingAction?.type === 'unpublish'
              ? 'Unpublish page'
              : 'Delete page'
        }
        busyLabel={
          pendingAction?.type === 'publish'
            ? 'Publishing...'
            : pendingAction?.type === 'unpublish'
              ? 'Unpublishing...'
              : 'Deleting...'
        }
        busy={
          busyAction.slug === pendingAction?.slug && busyAction.type === pendingAction?.type
        }
        confirmButtonClassName={
          pendingAction?.type === 'delete' ? 'danger-button' : 'primary-button'
        }
        onConfirm={handlePendingAction}
        onClose={() => {
          if (!busyAction.slug) {
            setPendingAction(null);
          }
        }}
      />
    </div>
  );
}
