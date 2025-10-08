# Python Project Structure Example

## Recommended for: Data Science, ML, Python Web Apps, CLI Tools

```
my-python-project/
├── README.md                          # Project overview
├── .context/                          # AI/developer guidance
│   ├── README.md
│   ├── project-context.md
│   ├── ai-coordination-strategy.md
│   └── development-tracking.md
├── .env.example                       # Environment template
├── .gitignore                         # Use gitignore-python.txt
├── requirements.txt                   # Python dependencies
├── setup.py or pyproject.toml        # Package configuration (optional)
│
├── src/                              # Main application code
│   ├── __init__.py
│   ├── main.py                       # Entry point
│   ├── models/                       # Data models / ML models
│   │   ├── __init__.py
│   │   └── user_model.py
│   ├── services/                     # Business logic
│   │   ├── __init__.py
│   │   └── data_service.py
│   └── utils/                        # Helper functions
│       ├── __init__.py
│       └── helpers.py
│
├── tests/                            # Test suite
│   ├── __init__.py
│   ├── test_models.py
│   └── test_services.py
│
├── data/                             # Data files (add to .gitignore if large)
│   ├── raw/                          # Raw data
│   ├── processed/                    # Processed data
│   └── .gitkeep
│
├── notebooks/                        # Jupyter notebooks (for data science)
│   └── exploratory_analysis.ipynb
│
├── docs/                             # Additional documentation (optional)
│   ├── architecture-diagrams/
│   └── api-documentation.md
│
└── scripts/                          # Utility scripts
    └── setup_database.py
```

## Common Python Patterns

### Web App (Flask/Django)
```
src/
├── app.py or manage.py              # Entry point
├── routes/                          # API routes
├── models/                          # Database models
├── templates/                       # HTML templates
├── static/                          # CSS, JS, images
└── config/                          # App configuration
```

### Data Science / ML
```
src/
├── data/                            # Data loading/processing
├── features/                        # Feature engineering
├── models/                          # ML model definitions
├── training/                        # Training scripts
├── evaluation/                      # Model evaluation
└── visualization/                   # Plotting utilities
```

### CLI Tool
```
src/
├── cli.py                          # CLI entry point
├── commands/                       # Command implementations
├── core/                           # Core functionality
└── utils/                          # Helper functions
```

## Installation

```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run application
python src/main.py
```

## Dependencies (requirements.txt example)

```
# Core dependencies
requests==2.31.0
python-dotenv==1.0.0

# Web framework (if applicable)
flask==3.0.0
django==5.0.0

# Data science (if applicable)
numpy==1.26.0
pandas==2.1.0
scikit-learn==1.3.0
matplotlib==3.8.0

# Testing
pytest==7.4.0
pytest-cov==4.1.0
```
