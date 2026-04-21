import { useState, useTransition } from 'react';

export function LoginPage({ onSubmit, error, authReady }) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isPending, startTransition] = useTransition();

  function handleSubmit(event) {
    event.preventDefault();
    startTransition(() => {
      onSubmit(email, password).catch(() => {});
    });
  }

  return (
    <div className="login-shell">
      <section className="login-panel">


        <form className="login-form" onSubmit={handleSubmit}>
          <div className="login-form-head">
            <h2>Admin Login</h2>
            <p>Use your admin credentials.</p>
          </div>

          <label className="field">
            <span>Email</span>
            <input
              type="email"
              value={email}
              onChange={(event) => setEmail(event.target.value)}
              placeholder="admin@example.com"
              autoComplete="email"
              required
            />
          </label>

          <label className="field">
            <span>Password</span>
            <input
              type="password"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              placeholder="Enter your password"
              autoComplete="current-password"
              required
            />
          </label>

          {error ? <div className="form-alert">{error}</div> : null}
          {!authReady ? (
            <div className="form-alert">
              Auth is not ready.
            </div>
          ) : null}

          <button
            className="primary-button"
            type="submit"
            disabled={isPending || !authReady}
          >
            {isPending ? 'Signing in...' : 'Sign in'}
          </button>
        </form>
      </section>
    </div>
  );
}
