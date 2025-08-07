# Deployment Guide

This application is configured for deployment using [Tomo](https://tomo-deploy.com/), a command-line tool for deploying Ruby applications. The configuration can be found in `.tomo/config.rb`.

## Prerequisites

Before deploying, ensure the following requirements are met:

*   **Local Machine**: Tomo must be installed on your local development machine.
    ```bash
    gem install tomo
    ```
*   **Target Server**:
    *   A server (e.g., running a Linux distribution like Ubuntu) with SSH access.
    *   `rbenv` and `nodenv` installed for managing Ruby and Node.js versions, respectively.
    *   A PostgreSQL database server accessible from the application server.

## Configuration

You must configure the deployment settings in `.tomo/config.rb` before the first deployment.

1.  **Set the Host**: Update the `host` setting with your server's SSH user and address.
    ```ruby
    # .tomo/config.rb
    host "user@your-server-ip-address"
    ```

2.  **Set the Git URL**: Update the `git_url` with the repository's clone URL. The server must have SSH access to this repository.
    ```ruby
    # .tomo/config.rb
    set git_url: "git@github.com:lperezpro/nearsure_game_of_life_rails.git" # Or your fork
    ```

## First-Time Setup

To prepare the server for the first time, run the `tomo setup` command. This will:
*   Clone the repository to the server.
*   Install the correct Ruby and Node.js versions.
*   Install dependencies using Bundler and Yarn.
*   Create and set up the production database.
*   Configure and enable the Puma systemd service.

```bash
tomo setup
```
During this process, you will be prompted to enter the `DATABASE_URL`.

## Deploying Updates

To deploy new changes from the `main` branch to the server, run the `tomo deploy` command. This task will:
*   Pull the latest code from the repository.
*   Install any new dependencies.
*   Run database migrations.
*   Precompile assets.
*   Restart the Puma application server to apply the changes.

```bash
tomo deploy
```

## Environment Variables

The application's behavior in production is controlled by environment variables. These are configured in `.tomo/config.rb` within the `env_vars` hash.

| Variable | Description | Default in Tomo Config |
| :--- | :--- | :--- |
| `RAILS_ENV` | **REQUIRED**. Sets the Rails environment. | `"production"` |
| `DATABASE_URL` | **REQUIRED**. The connection string for the PostgreSQL database. | `:prompt` (asks during setup) |
| `SECRET_KEY_BASE` | **REQUIRED**. A unique secret for signing cookies and sensitive data. | `:generate_secret` (auto-generated) |
| `RUBY_YJIT_ENABLE` | Enables Ruby's YJIT compiler for performance improvements. | `"1"` |
| `RAILS_MAX_THREADS` | The number of threads per Puma process. | `3` (Puma default) |
| `WEB_CONCURRENCY` | The number of Puma worker processes. | `1` (Puma default) |
| `RAILS_DISABLE_SSL` | Set to `1` to disable HSTS and secure cookies if not running behind an SSL/TLS proxy. | Not set by default. |
