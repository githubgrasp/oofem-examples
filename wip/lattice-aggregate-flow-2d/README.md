> **⚠️ Work in progress** — this example is not yet ready for use as a
> tutorial. The mesh pipeline (aggregate → generator → converter) is settling
> down, but the analysis side still needs work: realistic material parameters
> (the current ones use unphysical units chosen for visual contrast, with a
> 10 000× matrix/aggregate `D` ratio), a 1D analytic reference for validation,
> and a clearer narrative. Not listed in the top-level `README.md` until
> these are addressed.

Example illustrating how transport goes through disk arrangement in 2D. This can be interpreted as fibres.
Use aggregate to generate circular inclusions.
Give inclusions low permeability
Give matrix high permeability.
Subject boundary to be fully saturated and use lumped capacity (already implemented in 3D transport lattice element) to model the transport into the heterogeneous material
