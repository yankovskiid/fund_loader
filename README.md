# Fund Load Restrictions Processing

This Ruby application processes fund load attempts, enforcing velocity limits and special sanctions to ensure compliance with financial rules.

## Key Features

- **Velocity Limits**:
  - Daily and weekly load amount limits per customer.
  - Daily maximum load attempts limit.
- **Special Sanctions**:
  - Prime ID restrictions.
  - Monday load amount multiplier.
- **Configuration**:
  - Limits are configurable via `config/config.yml`.
- **Design**:
  - Uses Strategy Pattern for extensible rule handling.
  - Adheres to SOLID design principles.

## Input and Output

- **Input**: Reads JSON lines from `input/input.txt`.
- **Output**: Writes JSON responses to `output/output.txt`.

## Setup Instructions

1. **Install Ruby**: Ensure Ruby version 2.7 or higher is installed.
2. **Install Dependencies**:
   ```bash
   bundle install
   ```
3. **Run the Processor**:
   ```bash
   ruby bin/process_fund_loads.rb
   ```

## Directory Structure

- `bin/`: Contains the executable script for processing fund loads.
- `config/`: Holds configuration files (`config.yml`).
- `app/`: Contains models, repositories, strategies, and services.
- `input/`: Directory for input files.
- `output/`: Directory for output files.

## License

This project is licensed under the MIT License.
