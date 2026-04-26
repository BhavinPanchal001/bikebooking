import { useDeferredValue, useMemo, useState } from 'react';
import { ActionMenu } from '../components/ActionMenu';
import { ConfirmDialog } from '../components/ConfirmDialog';
import { FeedbackBanner } from '../components/FeedbackBanner';
import { PanelCard } from '../components/PanelCard';
import { adminUsersService } from '../services/adminUsersService';
import { formatCurrency, formatDate, formatDateTime } from '../utils/format';

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
          (filter === 'blocked' && user.accountStatus === 'blocked') ||
          user.verificationStatus === filter;

        return matchesSearch && matchesFilter;
      }),
    [data.users, deferredSearch, filter],
  );

  const dialogConfig = getDialogConfig(pendingAction);

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
        subtitle="Seller and buyer health in one place."
        actions={
          <div className="filter-row">
            {['all', 'reported', 'active', 'blocked', 'verified', 'incomplete'].map((status) => (
              <button
                key={status}
                type="button"
                className={`filter-chip ${filter === status ? 'filter-chip-active' : ''}`}
                onClick={() => setFilter(status)}
              >
                {status}
              </button>
            ))}
          </div>
        }
      >
        <FeedbackBanner tone="error">{actionError}</FeedbackBanner>
        <FeedbackBanner tone="success">{successMessage}</FeedbackBanner>

        <div className="toolbar">
          <input
            className="search-input"
            type="search"
            value={search}
            onChange={(event) => setSearch(event.target.value)}
            placeholder="Search users by name, phone, email, or location"
          />
          <div className="toolbar-note">{filteredUsers.length} users visible</div>
        </div>

        <div className="user-grid">
          {data.loading ? (
            <div className="empty-state">Loading live users...</div>
          ) : filteredUsers.length > 0 ? (
            filteredUsers.map((user) => {
              const isBlocked = user.accountStatus === 'blocked';
              const accountActionType = isBlocked ? 'unblock' : 'block';
              const accountActionBusyKey = `${accountActionType}:${user.id}`;

              return (
                <article key={user.id} className="user-card">
                  <div className="user-card-head">
                    <div>
                      <h4>{user.fullName}</h4>
                      <p>{user.location?.address || 'Location not shared'}</p>
                    </div>
                    <div className="row-actions">
                      <span className={`status-pill status-${isBlocked ? 'blocked' : 'approved'}`}>
                        {user.accountStatus}
                      </span>
                      <span className={`status-pill status-${user.verificationStatus}`}>
                        {user.verificationStatus}
                      </span>
                    </div>
                  </div>
                  <div className="user-card-body">
                    <div>
                      <span>Email</span>
                      <strong>{user.email || 'Not added'}</strong>
                    </div>
                    <div>
                      <span>Phone</span>
                      <strong>{user.phoneNumber || 'Not added'}</strong>
                    </div>
                    <div>
                      <span>Joined</span>
                      <strong>{formatDate(user.joinedAt)}</strong>
                    </div>
                    <div>
                      <span>Active listings</span>
                      <strong>{user.activeListings}</strong>
                    </div>
                    <div>
                      <span>Total sales</span>
                      <strong>{formatCurrency(user.totalSales)}</strong>
                    </div>
                    <div>
                      <span>Seller rating</span>
                      <strong>{user.rating > 0 ? user.rating.toFixed(1) : 'New'}</strong>
                    </div>
                    <div>
                      <span>Reports</span>
                      <strong>
                        {user.reportCount > 0
                          ? `${user.reportCount} total · ${user.openReportCount} open`
                          : 'None'}
                      </strong>
                    </div>
                  </div>
                  <div className="user-card-footer">
                    <div className="user-card-note">
                      {user.reportCount > 0
                        ? `Latest report ${formatDateTime(user.latestReportAt)}${user.reportReasons?.[0] ? ` · ${user.reportReasons[0]}` : ''}`
                        : isBlocked
                          ? `Blocked ${user.adminBlockedAt ? formatDate(user.adminBlockedAt) : 'recently'}${user.adminBlockedBy ? ` by ${user.adminBlockedBy}` : ''}`
                          : 'Account is active in the admin panel.'}
                    </div>
                    <div className="row-actions">
                      <button
                        type="button"
                        className={isBlocked ? 'secondary-button' : 'danger-button'}
                        disabled={busyActionKey === accountActionBusyKey}
                        onClick={() => {
                          clearFeedback();
                          setPendingAction({ type: accountActionType, user });
                        }}
                      >
                        {busyActionKey === accountActionBusyKey
                          ? isBlocked
                            ? 'Unblocking...'
                            : 'Blocking...'
                          : isBlocked
                            ? 'Unblock user'
                            : 'Block user'}
                      </button>
                      <ActionMenu
                        label="More"
                        items={[
                          {
                            key: 'delete',
                            label: 'Delete user',
                            tone: 'danger',
                            disabled: busyActionKey === `delete:${user.id}`,
                            onSelect() {
                              clearFeedback();
                              setPendingAction({ type: 'delete', user });
                            },
                          },
                        ]}
                      />
                    </div>
                  </div>
                </article>
              );
            })
          ) : (
            <div className="empty-state">No users matched the current filters.</div>
          )}
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
