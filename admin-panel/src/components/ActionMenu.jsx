import { useEffect, useRef, useState } from 'react';
import { Link } from 'react-router-dom';

function ActionIcon({ name }) {
  const commonProps = {
    width: '14',
    height: '14',
    viewBox: '0 0 24 24',
    fill: 'none',
    stroke: 'currentColor',
    strokeWidth: '2.2',
    strokeLinecap: 'round',
    strokeLinejoin: 'round',
    'aria-hidden': 'true',
  };

  switch (name) {
    case 'details':
      return (
        <svg {...commonProps}>
          <path d="M7 17 17 7" />
          <path d="M9 7h8v8" />
        </svg>
      );
    case 'approve':
      return (
        <svg {...commonProps}>
          <path d="m5 12 4 4L19 6" />
        </svg>
      );
    case 'flag':
      return (
        <svg {...commonProps}>
          <path d="M6 20V5" />
          <path d="M6 5h11l-2 5 2 5H6" />
        </svg>
      );
    case 'reopen':
      return (
        <svg {...commonProps}>
          <path d="M4 12a8 8 0 0 1 13.6-5.7" />
          <path d="M18 3v5h-5" />
          <path d="M20 12a8 8 0 0 1-13.6 5.7" />
          <path d="M6 21v-5h5" />
        </svg>
      );
    case 'close':
      return (
        <svg {...commonProps}>
          <path d="M6 6l12 12" />
          <path d="M18 6 6 18" />
        </svg>
      );
    case 'delete':
      return (
        <svg {...commonProps}>
          <path d="M4 7h16" />
          <path d="M10 11v6" />
          <path d="M14 11v6" />
          <path d="M6 7l1 14h10l1-14" />
          <path d="M9 7V4h6v3" />
        </svg>
      );
    default:
      return null;
  }
}

export function ActionMenu({
  label = 'Manage',
  items,
  align = 'end',
  iconOnly = false,
}) {
  const [open, setOpen] = useState(false);
  const rootRef = useRef(null);

  useEffect(() => {
    function handlePointerDown(event) {
      if (!rootRef.current?.contains(event.target)) {
        setOpen(false);
      }
    }

    function handleEscape(event) {
      if (event.key === 'Escape') {
        setOpen(false);
      }
    }

    window.addEventListener('pointerdown', handlePointerDown);
    window.addEventListener('keydown', handleEscape);
    return () => {
      window.removeEventListener('pointerdown', handlePointerDown);
      window.removeEventListener('keydown', handleEscape);
    };
  }, []);

  const visibleItems = items.filter(Boolean);

  return (
    <div className="action-menu" ref={rootRef}>
      <button
        type="button"
        className={`action-menu-trigger ${iconOnly ? 'action-menu-trigger-icon' : ''} ${
          open ? 'action-menu-trigger-open' : ''
        }`}
        aria-haspopup="menu"
        aria-expanded={open}
        aria-label={iconOnly ? label : undefined}
        title={iconOnly ? label : undefined}
        onClick={() => setOpen((current) => !current)}
      >
        {iconOnly ? (
          <span className="action-menu-dots" aria-hidden="true">
            <span />
            <span />
            <span />
          </span>
        ) : (
          label
        )}
      </button>

      {open ? (
        <div
          className={`action-menu-popover action-menu-popover-${align}`}
          role="menu"
        >
          {visibleItems.map((item) => {
            const className = `action-menu-item ${
              item.tone === 'danger' ? 'action-menu-item-danger' : ''
            }`;

            if (item.to) {
              return (
                <Link
                  key={item.key}
                  to={item.to}
                  className={className}
                  role="menuitem"
                  onClick={() => setOpen(false)}
                >
                  {item.icon ? <span className="action-menu-item-icon"><ActionIcon name={item.icon} /></span> : null}
                  {item.label}
                </Link>
              );
            }

            return (
              <button
                key={item.key}
                type="button"
                className={className}
                role="menuitem"
                disabled={item.disabled}
                onClick={() => {
                  setOpen(false);
                  item.onSelect?.();
                }}
              >
                {item.icon ? <span className="action-menu-item-icon"><ActionIcon name={item.icon} /></span> : null}
                {item.label}
              </button>
            );
          })}
        </div>
      ) : null}
    </div>
  );
}
