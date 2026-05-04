import { useDeferredValue, useMemo, useState } from 'react';
import { ActionMenu } from '../components/ActionMenu';
import { FeedbackBanner } from '../components/FeedbackBanner';
import { PanelCard } from '../components/PanelCard';
import { formatCompactNumber, formatDateTime } from '../utils/format';

const filters = [
  { key: 'all', label: 'All reported' },
  { key: 'attention', label: 'Needs review' },
  { key: 'resolved', label: 'Resolved' },
];

function matchesFilter(person, filter) {
  if (filter === 'attention') {
    return person.openReportCount > 0;
  }

  if (filter === 'resolved') {
    return person.reportCount > 0 && person.openReportCount === 0;
  }

  return true;
}

function getAttentionBadgeClass(person) {
  if (person.openReportCount === 0) {
    return 'status-approved';
  }

  return person.openReportCount > 1 || person.highestPriority === 'high'
    ? 'status-high'
    : 'status-reviewing';
}

function getAttentionLabel(person) {
  if (person.openReportCount === 0) {
    return 'resolved';
  }

  return person.openReportCount > 1 ? 'escalated' : 'needs review';
}

function getFeedMessage(data) {
  if (data.loading) {
    return 'Loading reported persons.';
  }

  if (data.source === 'firebase') {
    return 'Showing live Firestore reports grouped by account.';
  }

  if (data.source === 'firebase-partial') {
    return 'Showing Firestore data with partial access.';
  }

  return 'Showing demo report data.';
}

function summarizeDetails(text) {
  const trimmed = String(text || '').trim();
  if (!trimmed) {
    return 'No additional details provided.';
  }

  if (trimmed.length <= 80) {
    return trimmed;
  }

  return `${trimmed.slice(0, 77)}...`;
}

function formatStatusLabel(value) {
  if (!value) return 'Unknown';
  return value.charAt(0).toUpperCase() + value.slice(1);
}

export function ReportedPersonsPage({ data }) {
  const [search, setSearch] = useState('');
  const [filter, setFilter] = useState('all');
  const deferredSearch = useDeferredValue(search);

  const filteredPersons = useMemo(
    () =>
      data.reportedUsers.filter((person) => {
        const haystack = [
          person.fullName,
          person.email,
          person.phoneNumber,
          person.location?.address,
          person.reportReasons?.join(' '),
          person.reporterNames?.join(' '),
          person.latestDetails,
        ]
          .filter(Boolean)
          .join(' ')
          .toLowerCase();

        const matchesSearch =
          !deferredSearch || haystack.includes(deferredSearch.toLowerCase());

        return matchesSearch && matchesFilter(person, filter);
      }),
    [data.reportedUsers, deferredSearch, filter],
  );

  return (
    <div className="page-stack">
      <PanelCard
        title="Reported persons"
        subtitle="Review and manage accounts flagged by the community for moderation review."
      >
        <div className="live-note">
          <span className={`dot dot-${data.source}`} />
          {getFeedMessage(data)}
        </div>

        <FeedbackBanner tone="error">{data.error}</FeedbackBanner>

        <div className="toolbar listing-toolbar">
          <label className="listing-search-field">
            <span>Search queue</span>
            <input
              className="search-input"
              type="search"
              value={search}
              onChange={(event) => setSearch(event.target.value)}
              placeholder="Name, reason, details, or reporter"
            />
          </label>
          <label className="listing-status-filter">
            <span>Filter</span>
            <select
              value={filter}
              onChange={(event) => setFilter(event.target.value)}
            >
              {filters.map((item) => (
                <option key={item.key} value={item.key}>
                  {item.label}
                </option>
              ))}
            </select>
          </label>
          <div className="listing-toolbar-note">
            <strong>{filteredPersons.length}</strong>
            <span>{filteredPersons.length === 1 ? 'account visible' : 'accounts visible'}</span>
          </div>
        </div>

        <div className="table-wrap listing-table-wrap">
          <table className="data-table listing-table">
            <thead>
              <tr>
                <th>Reported Person</th>
                <th>Status & Priority</th>
                <th>Latest Issue</th>
                <th>Reporters</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {data.loading ? (
                <tr>
                  <td colSpan="5">
                    <div className="empty-state">Loading reported persons...</div>
                  </td>
                </tr>
              ) : filteredPersons.length > 0 ? (
                filteredPersons.map((person) => (
                  <tr key={person.id}>
                    <td>
                      <div className="listing-identity">
                        <div>
                          <strong>{person.fullName || 'Unnamed user'}</strong>
                          <span>{person.location?.address || 'Location not shared'}</span>
                        </div>
                        <div className="listing-meta-row">
                          <span
                            className={`status-pill status-${
                              person.accountStatus === 'blocked' ? 'blocked' : 'approved'
                            }`}
                          >
                            {formatStatusLabel(person.accountStatus)}
                          </span>
                        </div>
                      </div>
                    </td>
                    <td>
                      <div className="listing-review-cell" style={{ display: 'flex', gap: '4px', flexDirection: 'column' }}>
                        <span className={`status-pill ${getAttentionBadgeClass(person)}`}>
                          {getAttentionLabel(person)}
                        </span>
                        <div className="listing-meta-row">
                          <strong>{person.reportCount} reports</strong>
                          <span>{person.highestPriority || 'low'} priority</span>
                        </div>
                      </div>
                    </td>
                    <td>
                      <div className="listing-identity">
                        <strong>{person.latestReason || 'User report'}</strong>
                        <p style={{ margin: '4px 0', fontSize: '0.85rem', color: 'var(--muted)', maxWidth: '280px' }}>
                          {summarizeDetails(person.latestDetails)}
                        </p>
                        <div className="listing-meta-row">
                          <span>{formatDateTime(person.latestReportAt)}</span>
                        </div>
                      </div>
                    </td>
                    <td>
                      <div className="listing-seller-cell">
                        <strong>
                          {person.reporterCount || person.reporterNames?.length || 0} reporter
                          {(person.reporterCount || person.reporterNames?.length || 0) === 1
                            ? ''
                            : 's'}
                        </strong>
                        <span style={{ maxWidth: '180px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                          {person.reporterNames?.length > 0
                            ? person.reporterNames.join(', ')
                            : 'Details not available'}
                        </span>
                      </div>
                    </td>
                    <td className="table-actions-cell">
                      <ActionMenu
                        label={`Manage ${person.fullName || 'account'}`}
                        iconOnly
                        items={[
                          {
                            key: 'view-user',
                            label: 'View user',
                            icon: 'details',
                            to: `/users?search=${encodeURIComponent(person.fullName || person.id)}`,
                          },
                        ]}
                      />
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan="5">
                    <div className="empty-state">
                      No reported persons matched the current filters.
                    </div>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </PanelCard>
    </div>
  );
}

