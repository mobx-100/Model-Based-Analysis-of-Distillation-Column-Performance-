# Model-Based Analysis of Distillation Column Performance

A MATLAB-based simulation project for modeling, analyzing, and simulating the steady-state and dynamic behavior of an ideal binary distillation column. The implementation follows the mathematical framework presented in **Module 10: Ideal Binary Distillation (Bequette, 1998)** and demonstrates process dynamics, equilibrium relationships, and linearized state-space modeling. :contentReference[oaicite:1]{index=1}

---

## Project Overview

Distillation is one of the most important separation processes in the chemical industry. This project develops a mathematical model of an ideal binary distillation column and performs:

- Steady-state composition analysis
- Dynamic simulation using nonlinear differential equations
- State-space linearization
- Response analysis under varying operating conditions
- Visualization of composition profiles

The implementation is carried out entirely in **MATLAB**.

---

## Objectives

- Develop mathematical models for an ideal binary distillation column.
- Solve nonlinear steady-state equations.
- Simulate transient column dynamics using MATLAB.
- Analyze liquid composition profiles across trays.
- Generate a linearized state-space representation.
- Visualize the effect of operating parameter changes.

---

## Methodology

The simulation is based on:

- Constant Relative Volatility assumption
- Equimolar Overflow assumption
- Dynamic component material balances
- Vapor-Liquid Equilibrium (VLE)
- Numerical solution of nonlinear equations
- ODE45 integration for dynamic simulation
- State-space linearization around the steady-state operating point

The mathematical framework is adapted from **Bequette's Process Control textbook (Module 10: Ideal Binary Distillation)**. :contentReference[oaicite:2]{index=2}

---

## Repository Structure

```
.
├── dynamic/                         # Dynamic simulation scripts
├── graphs/                          # Generated plots
├── compute_lin_distillation.m       # State-space linearization
├── dist_dyn.m                       # Dynamic model
├── dist_ss.m                        # Steady-state model
├── lin_dist_ABCs.mat                # Linearized A, B, C matrices
├── run_distillation_simulation.m    # Run steady-state simulation
├── run_dyst_dyn.m                   # Run dynamic simulation
├── distillation_simulation_results.mat
├── distillation_simulation_results.xlsx
└── README.md
```

---

## Features

- Binary distillation column modeling
- Steady-state solver
- Dynamic simulation using MATLAB ODE45
- State-space model generation
- Composition profile visualization
- MATLAB result export
- Graph generation

---

## Requirements

- MATLAB R2020a or later
- Optimization Toolbox
- Control System Toolbox (recommended)

---

## Running the Project

### 1. Steady-State Simulation

```matlab
run_distillation_simulation
```

This computes the steady-state liquid composition profile across the column.

### 2. Dynamic Simulation

```matlab
run_dyst_dyn
```

This performs nonlinear dynamic simulation and generates transient response plots.

---

## Simulation Outputs

The project produces:

- Stage-wise liquid composition profile
- Dynamic response curves
- MATLAB `.mat` result files
- Excel output of simulation data
- Linearized state-space matrices

---

## Results

The developed model demonstrates:

- Accurate steady-state composition distribution
- Dynamic response to process disturbances
- Effect of operating conditions on column performance
- Linearized system suitable for control analysis

---

## Future Improvements

- Model Predictive Control (MPC)
- PID Controller Design
- Multicomponent Distillation
- Energy Optimization
- GUI-based Simulation Interface
- Interactive Parameter Analysis

---

## References

1. Bequette, B. W. *Process Control: Modeling, Design, and Simulation*, Module 10 – Ideal Binary Distillation, Prentice Hall, 1998. :contentReference[oaicite:3]{index=3}
2. W. L. McCabe, J. C. Smith and P. Harriott, *Unit Operations of Chemical Engineering*.
3. W. L. Luyben, *Process Modeling, Simulation and Control for Chemical Engineers*.

---

## Author

**Gaurav Gupta**

B.Tech, Chemical Engineering and Technology  
Indian Institute of Technology (BHU), Varanasi

---

## License

This project is intended for academic and educational purposes.
