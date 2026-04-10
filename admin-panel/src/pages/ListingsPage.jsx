import { useDeferredValue, useState } from 'react';
import { PanelCard } from '../components/PanelCard';
import { formatCurrency, formatDateTime } from '../utils/format';

export function ListingsPage({ data }) {
  const [search, setSearch] = useState('');
  const [filter, setFilter] = useState('all');
  const deferredSearch = useDeferredValue(search);

  const filteredListings = data.listings.filter((listing) => {
    const matchesSearch =
      !deferredSearch ||
      `${listing.title} ${listing.brand} ${listing.sellerName} ${listing.location}`
        .toLowerCase()
        .includes(deferredSearch.toLowerCase());

    const matchesFilter = filter === 'all' || listing.moderationStatus === filter;
    return matchesSearch && matchesFilter;
  });

  return (
    <div className="page-stack">
      <PanelCard
        title="Listing moderation"
        subtitle="Review fresh inventory, trace seller performance, and catch risky submissions early."
        actions={
          <div className="filter-row">
            {['all', 'approved', 'pending', 'flagged', 'closed'].map((status) => (
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
        <div className="live-note">
          <span className={`dot dot-${data.source}`} />
          {data.source === 'firebase'
            ? 'Listings are loading from your live Firestore products collection.'
            : 'Listings are showing demo data because Firebase could not be read.'}
        </div>

        <div className="toolbar">
          <input
            className="search-input"
            type="search"
            value={search}
            onChange={(event) => setSearch(event.target.value)}
            placeholder="Search by title, seller, brand, or city"
          />
          <div className="toolbar-note">{filteredListings.length} listings visible</div>
        </div>

        <div className="table-wrap">
          <table className="data-table">
            <thead>
              <tr>
                <th>Listing</th>
                <th>Category</th>
                <th>Seller</th>
                <th>Price</th>
                <th>Status</th>
                <th>Posted</th>
              </tr>
            </thead>
            <tbody>
              {filteredListings.map((listing) => (
                <tr key={listing.id}>
                  <td>
                    <div className="primary-cell">
                      <strong>{listing.title}</strong>
                      <span>
                        {listing.brand} · {listing.location}
                      </span>
                    </div>
                  </td>
                  <td>{listing.category}</td>
                  <td>{listing.sellerName}</td>
                  <td>{formatCurrency(listing.price)}</td>
                  <td>
                    <span className={`status-pill status-${listing.moderationStatus}`}>
                      {listing.moderationStatus}
                    </span>
                  </td>
                  <td>{formatDateTime(listing.createdAt)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </PanelCard>
    </div>
  );
}
