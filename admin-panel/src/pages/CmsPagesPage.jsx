import { useDeferredValue, useEffect, useMemo, useState } from 'react';
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

        <div className="toolbar">
          <input
            className="search-input"
            type="search"
            value={search}
            onChange={(event) => setSearch(event.target.value)}
            placeholder="Search pages by title, slug, or copy"
          />
          <div className="filter-row">
            {statusFilters.map((filter) => (
              <button
                key={filter.value}
                type="button"
                className={`filter-chip ${statusFilter === filter.value ? 'filter-chip-active' : ''}`.trim()}
                onClick={() => setStatusFilter(filter.value)}
              >
                {filter.label}
              </button>
            ))}
          </div>
          <div className="toolbar-note">{filteredPages.length} pages visible</div>
        </div>

        <div className="table-wrap">
          <table className="data-table">
            <thead>
              <tr>
                <th>Page</th>
                <th>Status</th>
                <th>Draft Version</th>
                <th>Last Published</th>
                <th>Published By</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan={6}>
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
                        <div className="primary-cell">
                          <strong>{record.title}</strong>
                          <span>{record.slug}</span>
                          <span>{record.previewText || 'No preview text yet.'}</span>
                        </div>
                      </td>
                      <td>
                        <div className="status-cluster">
                          <span className={getStatusClassName(record)}>{getStatusLabel(record)}</span>
                          {record.hasDraftChanges && record.publishedVersion > 0 ? (
                            <span className="cms-inline-note">
                              Draft changes are waiting to be published.
                            </span>
                          ) : null}
                        </div>
                      </td>
                      <td>
                        <div className="primary-cell">
                          <strong>v{record.version}</strong>
                          <span>
                            {record.publishedVersion > 0
                              ? `Live version v${record.publishedVersion}`
                              : 'Not published yet'}
                          </span>
                        </div>
                      </td>
                      <td>{formatDateTime(record.publishedAt)}</td>
                      <td>{record.publishedByEmail || '-'}</td>
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
                            className="primary-button"
                            disabled={isPublishing || isSaving}
                            onClick={() =>
                              setPendingAction({
                                type: 'publish',
                                slug: record.slug,
                                title: record.title,
                              })
                            }
                          >
                            {isPublishing ? 'Publishing...' : publishLabel}
                          </button>
                          {record.isPublished ? (
                            <button
                              type="button"
                              className="secondary-button"
                              disabled={isUnpublishing || isSaving}
                              onClick={() =>
                                setPendingAction({
                                  type: 'unpublish',
                                  slug: record.slug,
                                  title: record.title,
                                })
                              }
                            >
                              {isUnpublishing ? 'Unpublishing...' : 'Unpublish'}
                            </button>
                          ) : null}
                          <button
                            type="button"
                            className="danger-button danger-button-soft"
                            disabled={isDeleting || isSaving}
                            onClick={() =>
                              setPendingAction({
                                type: 'delete',
                                slug: record.slug,
                                title: record.title,
                              })
                            }
                          >
                            {isDeleting ? 'Deleting...' : 'Delete'}
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })
              ) : (
                <tr>
                  <td colSpan={6}>
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
