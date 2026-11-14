# Orbit — team todo dashboard

Buildless first version of the Orbit leadership workspace. Open `dist/index.html` in a browser to use it.

Features included:

- Persistent task data in browser `localStorage`.
- Kanban board with native drag-and-drop.
- Create and edit tasks from the quick-capture modal.
- Overview KPIs, workload chart, activity feed, team and personal views.
- Workspace members and invite-code interaction.
- Lucide icons loaded from the npm package CDN.

The local data layer is intentionally isolated in `dist/app.js`. Replace `save()` and the seed data with a Supabase client integration when project credentials are available. Suggested production tables are documented in the implementation plan.
