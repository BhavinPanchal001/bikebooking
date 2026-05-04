import { useEffect, useState } from 'react';

const DURATION_PRESETS = [
  { days: 7, label: '7 days' },
  { days: 14, label: '14 days' },
  { days: 30, label: '30 days' },
];

function copyFor(action) {
  if (!action?.record) return null;

  const title = action.record.title || action.record.id;

  switch (action.type) {
    case 'grant':
      return {
        heading: 'Grant boost',
        description: `Grant a free admin boost to "${title}". This bypasses Razorpay and does not write a payments record.`,
        confirmLabel: 'Grant boost',
        busyLabel: 'Granting...',
        confirmButtonClassName: 'primary-button',
        field: 'duration',
      };
    case 'revoke':
      return {
        heading: 'Revoke boost',
        description: `Clear the boost fields on "${title}" immediately. This does not refund the seller — issue the refund from the Payments page if needed.`,
        confirmLabel: 'Revoke boost',
        busyLabel: 'Revoking...',
        confirmButtonClassName: 'danger-button',
        field: 'noteOnly',
      };
    case 'feature':
      return {
        heading: 'Feature on home',
        description: `Add "${title}" to the editorial featured rail. It will appear above paid boosts on the mobile home feed.`,
        confirmLabel: 'Feature listing',
        busyLabel: 'Featuring...',
        confirmButtonClassName: 'primary-button',
        field: 'noteOnly',
      };
    case 'unfeature':
      return {
        heading: 'Remove from featured',
        description: `Remove "${title}" from the editorial featured rail. The listing will drop back to the regular feed.`,
        confirmLabel: 'Unfeature',
        busyLabel: 'Updating...',
        confirmButtonClassName: 'danger-button',
        field: 'noteOnly',
      };
    default:
      return null;
  }
}

export function BoostActionDialog({ action, onClose, onConfirm }) {
  const copy = copyFor(action);
  const [days, setDays] = useState(7);
  const [note, setNote] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [localError, setLocalError] = useState('');

  useEffect(() => {
    setDays(7);
    setNote('');
    setSubmitting(false);
    setLocalError('');
  }, [action?.type, action?.record?.id]);

  if (!copy) return null;

  async function handleSubmit(event) {
    event.preventDefault();
    setLocalError('');

    const parsedDays = Number.parseInt(days, 10);
    if (copy.field !== 'noteOnly') {
      if (!Number.isFinite(parsedDays) || parsedDays <= 0) {
        setLocalError('Enter a positive number of days.');
        return;
      }
      if (parsedDays > 365) {
        setLocalError('Duration may not exceed 365 days.');
        return;
      }
    }

    setSubmitting(true);
    try {
      const payload = { note: note.trim() };
      if (copy.field === 'duration') payload.durationDays = parsedDays;
      if (copy.field === 'additionalDays') payload.additionalDays = parsedDays;
      const result = await onConfirm(payload);
      if (!result?.ok && result?.error) {
        setLocalError(result.error);
      }
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div
      className="dialog-backdrop"
      role="presentation"
      onClick={() => {
        if (!submitting) onClose();
      }}
    >
      <section
        className="dialog-card dialog-card-compact"
        role="dialog"
        aria-modal="true"
        aria-label={copy.heading}
        onClick={(event) => event.stopPropagation()}
      >
        <div className="dialog-head">
          <div>
            <h3>{copy.heading}</h3>
            <p>{copy.description}</p>
          </div>
        </div>

        <form className="dialog-form" onSubmit={handleSubmit}>
          {copy.field !== 'noteOnly' ? (
            <label className="field">
              <span>
                Duration (days)
              </span>
              <div className="filter-row">
                {DURATION_PRESETS.map((preset) => (
                  <button
                    key={preset.days}
                    type="button"
                    className={`filter-chip ${
                      Number(days) === preset.days ? 'filter-chip-active' : ''
                    }`}
                    onClick={() => setDays(preset.days)}
                    disabled={submitting}
                  >
                    {preset.label}
                  </button>
                ))}
              </div>
              <input
                type="number"
                min="1"
                max="365"
                value={days}
                onChange={(event) => setDays(event.target.value)}
                disabled={submitting}
                required
              />
            </label>
          ) : null}

          <label className="field">
            <span>Note (optional, written to audit log)</span>
            <textarea
              rows={2}
              value={note}
              onChange={(event) => setNote(event.target.value)}
              disabled={submitting}
              placeholder="e.g. Comp for reported verification issue"
            />
          </label>

          {localError ? (
            <div className="feedback-banner feedback-banner-error">
              {localError}
            </div>
          ) : null}

          <div className="dialog-actions">
            <button
              type="button"
              className="secondary-button"
              onClick={onClose}
              disabled={submitting}
            >
              Cancel
            </button>
            <button
              type="submit"
              className={copy.confirmButtonClassName}
              disabled={submitting}
            >
              {submitting ? copy.busyLabel : copy.confirmLabel}
            </button>
          </div>
        </form>
      </section>
    </div>
  );
}
