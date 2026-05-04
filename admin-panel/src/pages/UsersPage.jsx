import { useDeferredValue, useEffect, useMemo, useState } from 'react';
import { ActionMenu } from '../components/ActionMenu';
import { ConfirmDialog } from '../components/ConfirmDialog';
import { FeedbackBanner } from '../components/FeedbackBanner';
import { PanelCard } from '../components/PanelCard';
import { adminUsersService } from '../services/adminUsersService';
import { formatCurrency, formatDate, formatDateTime } from '../utils/format';

function formatStatusLabel(value) {
  if (!value) {
    return 'Unknown';
  }

  return value
    .split(/[_\s-]+/)
    .filter(Boolean)
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(' ');
}

function getDialogConfig(action) {
  if (!action?.user) {
    return null;
  }

  const userName = action.user.fullName || action.user.phoneNumber || action.user.id;

  switch (action.type) {
    case 'block':
      return {
        title: 'Block user',
        message: `Block "${userName}" in the admin panel? This writes a blocked state to the user record immediately.`,
        confirmLabel: 'Block user',
        busyLabel: 'Blocking...',
        confirmButtonClassName: 'danger-button',
      };
    case 'unblock':
      return {
        title: 'Unblock user',
        message: `Unblock "${userName}" and restore their account status to active?`,
        confirmLabel: 'Unblock user',
        busyLabel: 'Unblocking...',
        confirmButtonClassName: 'secondary-button',
      };
    case 'delete':
      return {
        title: 'Delete user',
        message: `Delete "${userName}" and clean up the user record, listings, chats, reports, and related Firestore documents? This action cannot be undone.`,
        confirmLabel: 'Delete user',
        busyLabel: 'Deleting...',
        confirmButtonClassName: 'danger-button',
      };
    default:
      return null;
  }
}

export function UsersPage({ data, adminEmail }) {
  const [search, setSearch] = useState('');
  const [filter, setFilter] = useState('all');
  const [pendingAction, setPendingAction] = useState(null);
  const [busyActionKey, setBusyActionKey] = useState('');
  const [actionError, setActionError] = useState('');
  const [successMessage, setSuccessMessage] = useState('');
  const deferredSearch = useDeferredValue(search);
  const [displayLimit, setDisplayLimit] = useState(20);

  useEffect(() => {
    setDisplayLimit(20);
  }, [search, filter]);

  const filteredUsers = useMemo(
    () =>
      data.users.filter((user) => {
        const matchesSearch =
          !deferredSearch ||
          `${user.fullName} ${user.email} ${user.phoneNumber} ${user.location?.address ?? ''}`
            .toLowerCase()
            .includes(deferredSearch.toLowerCase());

        const matchesFilter =
          filter === 'all' ||
          (filter === 'reported' && user.reportCount > 0) ||
          (filter === 'active' && user.accountStatus === 'active') ||
          (filter === 'blocked' && user.accountStatus === 'blocked');

        return matchesSearch && matchesFilter;
      }),
    [data.users, deferredSearch, filter],
  );

  const userSummary = useMemo(() => {
    const counts = data.users.reduce(
      (summary, user) => {
        summary.all += 1;

        if (user.reportCount > 0) {
          summary.reported += 1;
        }

        if (user.accountStatus === 'active') {
          summary.active += 1;
        }

        if (user.accountStatus === 'blocked') {
          summary.blocked += 1;
        }

        return summary;
      },
      { all: 0, reported: 0, active: 0, blocked: 0 },
    );

    return ['all', 'reported', 'active', 'blocked'].map((status) => ({
      status,
      count: counts[status] ?? 0,
    }));
  }, [data.users]);

  const dialogConfig = getDialogConfig(pendingAction);

  const displayedUsers = filteredUsers.slice(0, displayLimit);

  function clearFeedback() {
    setActionError('');
    setSuccessMessage('');
  }

  async function handleConfirmedAction() {
    if (!pendingAction?.user) {
      return;
    }

    const { user, type } = pendingAction;
    const busyKey = `${type}:${user.id}`;
    setBusyActionKey(busyKey);
    clearFeedback();

    try {
      if (type === 'block') {
        await adminUsersService.blockUser({
          userId: user.id,
          adminEmail,
        });
        setSuccessMessage(`${user.fullName || 'User'} was blocked successfully.`);
      }

      if (type === 'unblock') {
        await adminUsersService.unblockUser({ userId: user.id });
        setSuccessMessage(`${user.fullName || 'User'} was unblocked successfully.`);
      }

      if (type === 'delete') {
        await adminUsersService.deleteUser({ userId: user.id });
        setSuccessMessage(`${user.fullName || 'User'} was deleted successfully.`);
      }

      setPendingAction(null);
      data.refresh?.();
    } catch (error) {
      setActionError(error?.message || 'Unable to complete this user action.');
    } finally {
      setBusyActionKey('');
    }
  }

  return (
    <div className="page-stack">
      <PanelCard
        title="User directory"
        subtitle="Manage seller and buyer accounts and moderation states."
      >
        <FeedbackBanner tone="error">{actionError}</FeedbackBanner>
        <FeedbackBanner tone="success">{successMessage}</FeedbackBanner>

        <div className="toolbar listing-toolbar">
          <label className="listing-search-field">
            <span>Search users</span>
            <input
              className="search-input"
              type="search"
              value={search}
              onChange={(event) => setSearch(event.target.value)}
              placeholder="Name, phone, email, or location"
            />
          </label>
          <label className="listing-status-filter">
            <span>Filter</span>
            <select
              value={filter}
              onChange={(event) => setFilter(event.target.value)}
            >
              {userSummary.map(({ status, count }) => (
                <option key={status} value={status}>
                  {formatStatusLabel(status)} ({count})
                </option>
              ))}
            </select>
          </label>
          <div className="listing-toolbar-note">
            <strong>{filteredUsers.length}</strong>
            <span>{filteredUsers.length === 1 ? 'user visible' : 'users visible'}</span>
          </div>
        </div>

        <div className="table-wrap listing-table-wrap">
          <table className="data-table listing-table">
            <thead>
              <tr>
                <th>User</th>
                <th>Contact</th>
                <th>Activity</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {data.loading ? (
                <tr>
                  <td colSpan="5">
                    <div className="empty-state">Loading live users...</div>
                  </td>
                </tr>
              ) : displayedUsers.length > 0 ? (
                <>
                  {displayedUsers.map((user) => {
                    const isBlocked = user.accountStatus === 'blocked';
                    const accountActionType = isBlocked ? 'unblock' : 'block';

                    return (
                    <tr key={user.id}>
                      <td>
                        <div className="listing-identity">
                          <div>
                            <strong>{user.fullName || 'Unnamed user'}</strong>
                            <span>{user.location?.address || 'Location not shared'}</span>
                          </div>
                          <div className="listing-meta-row">
                            <span>Joined {formatDate(user.joinedAt)}</span>
                            {user.rating > 0 && <span>{user.rating.toFixed(1)} rating</span>}
                          </div>
                        </div>
                      </td>
                      <td>
                        <div className="listing-seller-cell">
                          <strong>{user.phoneNumber || 'No phone'}</strong>
                          <span>{user.email || 'No email'}</span>
                        </div>
                      </td>
                      <td>
                        <div className="listing-identity">
                          <div className="listing-meta-row">
                            <span>{user.activeListings} active</span>
                            <span>{formatCurrency(user.totalSales)} sales</span>
                          </div>
                          {user.reportCount > 0 && (
                            <div className="listing-meta-row">
                              <span style={{ color: 'var(--accent)', fontWeight: 600 }}>
                                {user.openReportCount} open reports
                              </span>
                            </div>
                          )}
                        </div>
                      </td>
                      <td>
                        <div className="listing-review-cell">
                          <span className={`status-pill status-${isBlocked ? 'blocked' : 'approved'}`}>
                            {formatStatusLabel(user.accountStatus)}
                          </span>
                        </div>
                      </td>
                      <td className="table-actions-cell">
                        <ActionMenu
                          label={`Manage ${user.fullName || user.phoneNumber || 'user'}`}
                          iconOnly
                          items={[
                            {
                              key: accountActionType,
                              label: isBlocked ? 'Unblock user' : 'Block user',
                              icon: isBlocked ? 'approve' : 'close',
                              tone: isBlocked ? 'default' : 'danger',
                              disabled: busyActionKey === `${accountActionType}:${user.id}`,
                              onSelect() {
                                clearFeedback();
                                setPendingAction({ type: accountActionType, user });
                              },
                            },
                            {
                              key: 'delete',
                              label: 'Delete user',
                              icon: 'delete',
                              tone: 'danger',
                              disabled: busyActionKey === `delete:${user.id}`,
                              onSelect() {
                                clearFeedback();
                                setPendingAction({ type: 'delete', user });
                              },
                            },
                          ]}
                        />
                      </td>
                    </tr>
                  );
                })}
                {displayLimit < filteredUsers.length && (
                  <tr>
                    <td colSpan="5" style={{ textAlign: 'center', padding: '2rem' }}>
                      <button 
                        type="button" 
                        className="secondary-button"
                        onClick={() => setDisplayLimit((prev) => prev + 50)}
                      >
                        Load more users
                      </button>
                    </td>
                  </tr>
                )}
                </>
              ) : (
                <tr>
                  <td colSpan="5">
                    <div className="empty-state">No users matched the current filters.</div>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </PanelCard>

      <ConfirmDialog
        open={Boolean(dialogConfig)}
        title={dialogConfig?.title}
        message={dialogConfig?.message}
        confirmLabel={dialogConfig?.confirmLabel}
        busyLabel={dialogConfig?.busyLabel}
        busy={Boolean(pendingAction?.user) && busyActionKey === `${pendingAction?.type}:${pendingAction?.user?.id}`}
        confirmButtonClassName={dialogConfig?.confirmButtonClassName}
        onConfirm={handleConfirmedAction}
        onClose={() => {
          if (!busyActionKey) {
            setPendingAction(null);
          }
        }}
      />
    </div>
  );
}

