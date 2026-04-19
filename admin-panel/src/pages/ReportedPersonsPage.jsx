import { useDeferredValue, useMemo, useState } from 'react';
import { FeedbackBanner } from '../components/FeedbackBanner';
import { PanelCard } from '../components/PanelCard';
import { StatCard } from '../components/StatCard';
import { formatCompactNumber, formatDateTime } from '../utils/format';

const filters = [
  { key: 'all', label: 'all' },
  { key: 'attention', label: 'needs review' },
  { key: 'resolved', label: 'resolved' },
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
    return 'Showing live Firestore reports grouped by reported seller or user.';
  }

  if (data.source === 'firebase-partial') {
    return 'Showing Firestore data with partial collection access.';
  }

  return 'Showing demo report data.';
}

function summarizeDetails(text) {
  const trimmed = String(text || '').trim();
  if (!trimmed) {
    return 'No additional details were added with the latest report.';
  }

  if (trimmed.length <= 110) {
    return trimmed;
  }

  return `${trimmed.slice(0, 107)}...`;
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

  const totalReports = data.reportedUsers.reduce(
    (sum, person) => sum + person.reportCount,
    0,
  );
  const openReports = data.reportedUsers.reduce(
    (sum, person) => sum + person.openReportCount,
    0,
  );
  const attentionCases = data.reportedUsers.filter(
    (person) => person.openReportCount > 0,
  ).length;
  const resolvedCases = data.reportedUsers.filter(
    (person) => person.reportCount > 0 && person.openReportCount === 0,
  ).length;
  const escalatedCases = data.reportedUsers.filter(
    (person) => person.openReportCount > 1 || person.highestPriority === 'high',
  ).length;

  return (
    <div className="page-stack">
      <section className="stats-grid">
        <StatCard
          label="Reported persons"
          value={formatCompactNumber(data.metrics.reportedUsers)}
          trend={`${formatCompactNumber(attentionCases)} needing review`}
          tone="primary"
          helper={`${formatCompactNumber(resolvedCases)} resolved`}
        />
        <StatCard
          label="Total reports"
          value={formatCompactNumber(totalReports)}
          trend={`${formatCompactNumber(openReports)} open reports`}
          tone="warning"
          helper="Grouped by reported account"
        />
        <StatCard
          label="Escalated cases"
          value={formatCompactNumber(escalatedCases)}
          trend="Multiple reports or high-risk reasons"
          tone="accent"
          helper="Fraud, abuse, or repeat complaints"
        />
        <StatCard
          label="Latest queue size"
          value={formatCompactNumber(filteredPersons.length)}
          trend={`${formatCompactNumber(data.reportedUsers.length)} total visible accounts`}
          tone="success"
          helper="Search and filters update this list"
        />
      </section>

      <PanelCard
        title="Reported persons"
        subtitle="A moderation queue grouped by person, with counts and latest report context."
        actions={
          <div className="filter-row">
            {filters.map((item) => (
              <button
                key={item.key}
                type="button"
                className={`filter-chip ${filter === item.key ? 'filter-chip-active' : ''}`}
                onClick={() => setFilter(item.key)}
              >
                {item.label}
              </button>
            ))}
          </div>
        }
      >
        <div className="live-note">
          <span className={`dot dot-${data.source}`} />
          {getFeedMessage(data)}
        </div>

        <FeedbackBanner tone="error">{data.error}</FeedbackBanner>

        <div className="toolbar">
          <input
            className="search-input"
            type="search"
            value={search}
            onChange={(event) => setSearch(event.target.value)}
            placeholder="Search by person, contact, reason, details, or reporter"
          />
          <div className="toolbar-note">
            {filteredPersons.length} reported persons visible
          </div>
        </div>

        <div className="table-wrap">
          <table className="data-table report-queue-table">
            <thead>
              <tr>
                <th>Person</th>
                <th>Reports</th>
                <th>Latest reason</th>
                <th>Reporter activity</th>
                <th>Contact</th>
                <th>Last report</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {data.loading ? (
                <tr>
                  <td colSpan="7">
                    <div className="empty-state">Loading reported persons...</div>
                  </td>
                </tr>
              ) : filteredPersons.length > 0 ? (
                filteredPersons.map((person) => (
                  <tr key={person.id}>
                    <td>
                      <div className="primary-cell">
                        <strong>{person.fullName}</strong>
                        <span>{person.location?.address || 'Location not shared'}</span>
                        <div className="status-cluster">
                          <span className={`status-pill status-${person.verificationStatus}`}>
                            {person.verificationStatus}
                          </span>
                          <span
                            className={`status-pill status-${
                              person.accountStatus === 'blocked' ? 'blocked' : 'approved'
                            }`}
                          >
                            {person.accountStatus}
                          </span>
                        </div>
                      </div>
                    </td>
                    <td>
                      <div className="primary-cell">
                        <strong>{person.reportCount} total</strong>
                        <span>{person.openReportCount} open reports</span>
                      </div>
                    </td>
                    <td>
                      <div className="primary-cell">
                        <strong>{person.latestReason || 'Seller report'}</strong>
                        <span>{summarizeDetails(person.latestDetails)}</span>
                        <div className="report-reason-row">
                          {person.reportReasons?.slice(0, 2).map((reason) => (
                            <span key={`${person.id}-${reason}`} className="report-reason-chip">
                              {reason}
                            </span>
                          ))}
                        </div>
                      </div>
                    </td>
                    <td>
                      <div className="primary-cell">
                        <strong>
                          {person.reporterCount || person.reporterNames?.length || 0} reporter
                          {(person.reporterCount || person.reporterNames?.length || 0) === 1
                            ? ''
                            : 's'}
                        </strong>
                        <span>
                          {person.reporterNames?.length > 0
                            ? person.reporterNames.join(', ')
                            : 'Reporter names not available'}
                        </span>
                      </div>
                    </td>
                    <td>
                      <div className="primary-cell">
                        <strong>{person.phoneNumber || 'Phone not added'}</strong>
                        <span>{person.email || 'Email not added'}</span>
                      </div>
                    </td>
                    <td>
                      <div className="primary-cell">
                        <strong>{formatDateTime(person.latestReportAt)}</strong>
                        <span>{person.highestPriority || 'low'} priority</span>
                      </div>
                    </td>
                    <td>
                      <div className="status-cluster">
                        <span className={`status-pill ${getAttentionBadgeClass(person)}`}>
                          {getAttentionLabel(person)}
                        </span>
                        <span className="report-count-pill">
                          {person.reportCount} report{person.reportCount === 1 ? '' : 's'}
                        </span>
                      </div>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan="7">
                    <div className="empty-state">
                      No reported persons matched the current search and filters.
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
