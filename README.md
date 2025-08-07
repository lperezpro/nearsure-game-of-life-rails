# Conway's Game of Life API

This project is a Ruby on Rails API implementation of Conway's Game of Life. It was developed to fulfill the requirements of a technical interview, focusing on creating a production-ready, stateful API service.

The application allows users to upload board states, simulate the game's progression, and determine the final outcome of a given pattern.

## Test Description

The detailed requirements for this project are outlined in the [`Backend_Test_Conway_Game_RoR.pdf`](./Backend_Test_Conway_Game_RoR.pdf) document.


## Core Requirements Met

*   **Upload Board State**: Allows uploading a new board state and returns a unique ID for the board.
*   **Get Next State**: For a given board ID, calculates and returns the next single generation.
*   **Get State 'n' Steps Away**: For a given board ID, calculates and returns the state after a specified number of generations.
*   **Get Final State**: For a given board ID, determines if the board reaches a stable or oscillating state. It returns an error if a conclusion isn't reached within a predefined number of attempts to prevent infinite loops.
*   **State Persistence**: Board states are saved in a PostgreSQL database, ensuring they persist across service restarts or crashes.
*   **Production-Ready Code**: The application is built with best practices, including a service-oriented architecture, comprehensive test coverage, and deployment configurations.

## Technology Stack

*   **Backend**: Ruby 3.4.4, Ruby on Rails 8.0
*   **Database**: PostgreSQL
*   **Testing**: RSpec, FactoryBot
*   **Deployment**: Tomo
*   **Containerization**: Docker, VS Code Dev Containers

## Setup and Installation (using Dev Containers)

The recommended way to run this project is by using the included Dev Container configuration with VS Code.

### Prerequisites

*   [Docker Desktop](https://www.docker.com/products/docker-desktop/)
*   [Visual Studio Code](https://code.visualstudio.com/)
*   [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) for VS Code.

### Steps

1.  **Clone the repository:**
    ```bash
    git clone <repository-url>
    cd nearsure_game_of_life_rails
    ```
2.  **Open in VS Code:**
    ```bash
    code .
    ```
3.  **Reopen in Container:**
  *   Open the command palette (`Ctrl+Shift+P` or `Cmd+Shift+P`).
  *   Run the **"Dev Containers: Reopen in Container"** command.
  *   VS Code will build the Docker container and set up the development environment. The `postCreateCommand` will automatically run `bin/setup` to install dependencies and create the database.

4.  **Start the Rails Server:**
    Once the container is running and setup is complete, open a new terminal within VS Code and start the server:
    ```bash
    rails s
    ```
The API will be available at `http://localhost:3000`.

## Running Tests

To run the full RSpec test suite, execute the following command in the container's terminal:

```bash
bundle exec rspec
```

## API Documentation (Swagger)

This project uses the `rswag` gem to generate and serve OpenAPI (Swagger) documentation directly from the RSpec request specs. This provides an interactive API documentation where you can explore and test the endpoints directly in your browser.

### Accessing the Documentation

Once the Rails server is running, you can access the Swagger UI at:

[http://localhost:3000/api-docs](http://localhost:3000/api-docs)

### Generating Documentation

The OpenAPI specification file (`swagger/v1/swagger.yaml`) is generated automatically when you run the test suite. If you make changes to the API documentation within the request specs (located in `spec/requests/`), you can regenerate the documentation by running the tests:

```bash
bundle exec rspec
```

## API Endpoints

A Postman collection is included in the root of this project (`Game of Life API.postman_collection.json`) for easy testing of the API endpoints.

The base URL is `http://localhost:3000`.

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `POST` | `/api/v1/boards` | Creates a new board. The body should be a JSON object with a `state` key containing a 2D array of 0s and 1s. Returns the new board's `id`. |
| `GET` | `/api/v1/boards` | Returns a list of all existing boards. |
| `DELETE` | `/api/v1/boards/:id` | Deletes the specified board. |
| `GET` | `/api/v1/boards/:id/next` | Returns the next single state (generation) for the specified board. |
| `GET` | `/api/v1/boards/:id/steps/:n` | Returns the state of the board after `n` steps (generations). |
| `GET` | `/api/v1/boards/:id/final` | Attempts to find a final (stable or oscillating) state. Returns an error if no conclusion is reached after a maximum number of attempts (default 1000). |

### Example: Create a Board

**Request:** `POST /api/v1/boards`

**Body:**
```json
{
    "board": {
        "state": [
            [0, 1, 0],
            [0, 1, 0],
            [0, 1, 0]
        ]
    }
}
```

**Response:** `201 Created`
```json
{
    "id": 1
}
```

## Deployment

The project is configured for deployment using [Tomo](https://tomo-deploy.com/). The configuration can be found in `.tomo/config.rb`. It handles tasks like cloning the repository, installing dependencies, running database migrations, and restarting the Puma server. You will need to update the `host` and `git_url` settings before use.
