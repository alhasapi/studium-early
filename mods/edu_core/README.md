# edu_core

Shared foundation for the educational game prototype.

It currently provides persistent per-player exercise progress through the global
`edu` table. Content modules should depend on this mod rather than implementing
progress storage independently.
