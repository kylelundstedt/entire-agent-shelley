# Security policy

This repository is a prototype. It is IV-authored, is not shipped or supported
by Entire, and carries no warranty — see `LICENSE`. Report security issues
privately to Kyle Lundstedt rather than opening a public issue.

Do not include credentials, tokens, private transcripts, borrower/customer PII
or NPPI, client-confidential material, privileged communications, or
license-restricted source material in reports or fixtures. Use synthetic
fixtures only.

The plugin's Phase 1 operating envelope assumes the repositories it captures
from are private, telemetry disabled, Entire's built-in credential detection as
a best-effort backstop, and an explicit prohibition on sensitive authoring
content. The plugin is not a PII or NPPI DLP boundary.

Publishing this source does not change that envelope: the plugin reads local
agent history and writes authoring context into the repository it is enabled
for. Operators remain responsible for what enters those repositories.
