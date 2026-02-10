# BaghSim: Tiger Population Dynamics Model
# https://doi.org/10.5281/zenodo.18554417

**Version:** 1.0.0
**Author:** Dr Indushree Banerjee
**Affiliation:** Water Management, Civil Engineering and Geosciences, TU Delft
**Contact:** i.banerjee@tudelft.nl ; banerjee.indushree@gmail.com 

## Overview

BaghSim is an individual-based model (IBM) simulating Royal Bengal Tiger (*Panthera tigris tigris*) behavior, movement, and population dynamics in a spatially explicit environment. The model represents a generic tiger habitat including national park, buffer zone, and surrounding areas.

The model simulates how tigers make decisions based on multiple needs (hunger, thirst, fatigue, exploration, mating, fear of competitors, and fear of humans), how they interact with their environment and each other, and how these individual behaviors generate emergent population-level patterns.

## Purpose

The model addresses the question:

> *Can individual-based tiger behavior based on resource needs, spatial memory, and social interactions produce realistic population dynamics and spatial patterns in a national park?*

BaghSim is designed to support tiger conservation research, allowing in-silico study of policy impacts such as fencing, buffer zone creation, and waterhole placement.

## Files

| File | Description |
|------|-------------|
| `BaghSim.nlogo` | NetLogo model (requires NetLogo 6.4.0 or later) |
| `BaghSim-ODD.md` | Full model documentation following the ODD protocol (Grimm et al., 2020) |
| `README.md` | This file |
| `LICENSE.md` | Usage terms and conditions |

## Requirements

- **NetLogo 6.4.0** or later ([download here](https://ccl.northwestern.edu/netlogo/download.shtml))
- No additional extensions required

## Quick Start

1. Open `BaghSim.nlogo` in NetLogo
2. Set parameters:
   - `Total-tiger-count`: Initial population (recommended: 20-50)
   - `scenario`: Landscape type (Default/Uniform/Clustered)
   - `river-type`: River configuration (none/central/boundary)
   - `num-of-water-channel`: Water availability (None/One/Two/Many)
3. Click **Setup** to initialize the world
4. Click **Initialize** to let tigers build environmental memory
5. Click **Go** to run the simulation

## Model Features

- **Needs-based behavior:** Tigers allocate energy proportionally across 7 needs
- **Spatial memory:** Tigers remember and return to resource locations
- **Territorial marking:** Emergent territories through scent marking behavior
- **Reproduction:** Mating, gestation, birth, and cub development
- **Competition:** Same-sex territorial fights with probabilistic outcomes
- **Mother-cub dynamics:** Maternal care and gradual cub independence

## Output

The model generates:
- GPS coordinate data (`output/BaghSim_GPScoordinates_Run*.csv`)
- Death records with causes (`output/BaghSim_death_records_Run*.csv`)
- Population statistics via interface monitors and plots

## Citation

If you use this model in your research, please cite:

> Banerjee, I., Grimm, V., Qureshi, Q., & Ertsen, M. (2026). BaghSim: Tiger Population Dynamics Model (Version 1.0.0) [Software]. Zenodo. https://doi.org/10.5281/zenodo.18554417

*https://doi.org/10.5281/zenodo.18554417*

## License

This software is provided for **educational and non-commercial use only**.

- Modifications, extensions, or commercial use require explicit written permission from the author.
- See `LICENSE.md` for full terms.

## Acknowledgments

This model was developed as part of research on tiger conservation and landscape connectivity at TU Delft. The model design is based on input from a participatory workshop with tiger experts and park managers.

*Save The Tiger, Save The Grasslands, Save The Water*

## References

- Grimm, V., et al. (2020). The ODD protocol for describing agent-based and other simulation models: A second update. JASSS, 23(2).
- Sadhu, A., et al. (2017). Demography of a small, isolated tiger population in western India. BMC Zoology, 2, 16.
- Sunquist, M. (2010). What is a tiger? Ecology and behavior. In: Tigers of the World, 2nd ed. Elsevier.

---

**Contact:** For questions, collaboration inquiries, or permission requests, contact Dr Indushree Banerjee at i.banerjee@tudelft.nl
