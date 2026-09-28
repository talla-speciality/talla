# Phase 7 — Advanced espresso and community

This phase is enabled only after scale-based espresso capture is dependable.

## Delivered foundation

- Typed pressure, flow, and temperature telemetry samples with normalized units.
- Reference overlay grouping and chronological sorting for the three streams.
- Manual refractometer/TDS entry and extraction-yield calculation.
- Capability-gated machine integrations: read-only streams are the default; control requires an explicit official adapter.
- Shared espresso profile, roaster-published recipe, equipment starting-point, and bottomless-portafilter assessment records.
- An advanced espresso panel attached to the existing Espresso Workspace.

## Safety and rollout boundaries

- No generic Bluetooth machine writes are permitted.
- “Official control” is a capability declaration, not an implementation of a machine protocol. A manufacturer adapter must be added and authorized before control is exposed.
- Bottomless-portafilter video notes are local until the customer explicitly shares them; shared content remains subject to moderation.
- Sensor and refractometer data remain optional. A shot is still valid when only scale data is available.

## Remaining integration work

1. Replace the sample integration descriptors with vendor-approved adapters and entitlements.
2. Persist advanced snapshots through the existing coffee sync contract.
3. Add authenticated API contracts for profile sharing, equipment starting points, and roaster recipe publishing.
4. Video upload is now available at `POST /community/espresso/videos/upload` with authenticated MP4/MOV/WebM uploads up to 100 MB and moderation metadata. Set `ESPRESSO_VIDEO_STORAGE_PATH` to a persistent volume or object-storage-mounted directory in production; the default data directory is for local development. Transcoding and automated vision analysis remain optional follow-on services.
5. Validate live sensor timing, calibration, and machine control on physical devices before enabling control in production.
