import { useEffect, useRef, useState } from 'react';
import { Link } from 'react-router-dom';

export function ActionMenu({
  label = 'Manage',
  items,
  align = 'end',
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
        className={`action-menu-trigger ${open ? 'action-menu-trigger-open' : ''}`}
        aria-haspopup="menu"
        aria-expanded={open}
        onClick={() => setOpen((current) => !current)}
      >
        {label}
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
                {item.label}
              </button>
            );
          })}
        </div>
      ) : null}
    </div>
  );
}
