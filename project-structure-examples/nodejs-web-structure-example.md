# Node.js / Web Development Project Structure Example

## Recommended for: React, Vue, Express, Next.js, Full-stack Web Apps

```
my-web-project/
├── README.md                          # Project overview
├── .context/                          # AI/developer guidance
│   ├── README.md
│   ├── project-context.md
│   ├── ai-coordination-strategy.md
│   └── development-tracking.md
├── .env.example                       # Environment template
├── .gitignore                         # Use gitignore-node.txt
├── package.json                       # Node.js dependencies & scripts
├── package-lock.json or yarn.lock    # Dependency lock file
│
├── src/                              # Source code
│   ├── index.js or index.ts          # Entry point
│   ├── App.jsx or App.tsx           # Main app component (React)
│   ├── components/                   # React/Vue components
│   │   ├── Header.jsx
│   │   ├── Footer.jsx
│   │   └── Button.jsx
│   ├── pages/                        # Page components
│   │   ├── Home.jsx
│   │   └── About.jsx
│   ├── services/                     # API services / business logic
│   │   └── api.js
│   ├── utils/                        # Helper functions
│   │   └── helpers.js
│   ├── hooks/                        # Custom React hooks
│   │   └── useAuth.js
│   ├── context/                      # React Context / State management
│   │   └── AuthContext.js
│   └── styles/                       # CSS/SCSS files
│       └── global.css
│
├── public/                           # Static assets
│   ├── index.html
│   ├── favicon.ico
│   └── images/
│
├── tests/ or __tests__/             # Test files
│   ├── components/
│   │   └── Button.test.jsx
│   └── utils/
│       └── helpers.test.js
│
├── docs/                             # Additional documentation (optional)
│   ├── architecture-diagrams/
│   └── api-documentation.md
│
└── config/                           # Build configuration (optional)
    ├── webpack.config.js
    └── jest.config.js
```

## Framework-Specific Patterns

### React (Create React App / Vite)
```
src/
├── App.jsx                          # Main app component
├── index.jsx                        # Entry point
├── components/                      # Reusable components
├── pages/                           # Page-level components
├── hooks/                           # Custom hooks
├── context/                         # React Context
├── services/                        # API calls
└── styles/                          # CSS modules
```

### Next.js (App Router)
```
app/
├── page.tsx                         # Home page
├── layout.tsx                       # Root layout
├── globals.css                      # Global styles
├── api/                             # API routes
│   └── route.ts
├── (routes)/                        # Route groups
│   ├── about/
│   │   └── page.tsx
│   └── dashboard/
│       └── page.tsx
└── components/                      # Shared components
```

### Express.js Backend
```
src/
├── server.js                        # Entry point
├── app.js                           # Express app setup
├── routes/                          # API routes
│   ├── users.js
│   └── posts.js
├── controllers/                     # Route controllers
│   └── userController.js
├── models/                          # Database models
│   └── User.js
├── middleware/                      # Custom middleware
│   └── auth.js
├── config/                          # Configuration
│   └── database.js
└── utils/                           # Helper functions
    └── validation.js
```

### Full-Stack (MERN/PERN)
```
project-root/
├── client/                          # Frontend (React)
│   ├── src/
│   ├── public/
│   └── package.json
├── server/                          # Backend (Express)
│   ├── src/
│   ├── config/
│   └── package.json
└── README.md                        # Mono-repo documentation
```

## Installation

```bash
# Install dependencies
npm install
# or
yarn install

# Run development server
npm run dev

# Build for production
npm run build

# Run tests
npm test
```

## Dependencies (package.json example)

```json
{
  "name": "my-web-project",
  "version": "1.0.0",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "test": "jest"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.20.0",
    "axios": "^1.6.0"
  },
  "devDependencies": {
    "vite": "^5.0.0",
    "@vitejs/plugin-react": "^4.2.0",
    "jest": "^29.7.0",
    "eslint": "^8.54.0"
  }
}
```
