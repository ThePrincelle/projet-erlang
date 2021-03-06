# Erlang project

[![Tests](https://github.com/ThePrincelle/projet-erlang/actions/workflows/tests.yml/badge.svg)](https://github.com/ThePrincelle/projet-erlang/actions/workflows/tests.yml)

Module simulating processes exchanging messages with matrix clocks.

**Author:** [Maxime Princelle](https://contact.princelle.org) (M1 SIL)

## How to make it work?

You need to have Erlang installed on your system.

### Compile

To compile the code, run:

```sh
erlc matrix_clocks.erl
```

### Run

To run the provided test, enter:

```erlang
erl % Enter the Erlang shell

matrix_clocks:test(N). % Run the test

init:stop(0). % Exit the shell
```

or:

```bash
erl -noshell -eval 'matrix_clocks:test(N), init:stop(0).'
```

Here, _N_ is the number of processes you want to simulate.

The test simply sends messages between the N processes. More info at [Provided test](#provided-test).

<br/>

## Automated testing

[![Tests](https://github.com/ThePrincelle/projet-erlang/actions/workflows/tests.yml/badge.svg)](https://github.com/ThePrincelle/projet-erlang/actions/workflows/tests.yml)

Every time a push is made to the repository, a test is automatically executed to verify that the Erlang script still passes through the compiler.

Then, one the step of the compiler is done, we run the test function with multiple scenarios to ensure that everything still passes. More info at [Provided test](#provided-test).

To run the test, we use the following image: https://hub.docker.com/_/erlang. This allow us to have a clean environment everytime.

Here's the link to the CI tester : https://drone.princelle.org/princelle/project-erlang

<br/>

## How does it work?

### Provided test

The included test separates 'even' sites to 'uneven' ones:

- All the 'even' sites receive a message from every 'uneven' ones then send back a message to each of them.
- All the 'uneven' sites send a message to each 'even' sites then receive a message from each of them.

### Rules

Here, we present a list of rules for each event when we use matrix clocks.

**Local progress rule**

$` \rightarrow `$ not used in this case.

before producing an internal event:

$` C_i[i,i] \gets C_i[i,i] +  1 `$

**Sending rule**

when sending a message $`m`$ to $`P_j`$:

$` C_i[i,i] \gets C_i[i,i] + 1 `$

$` send(m, C_i) \space to \space P_j `$

**Receiving rule**

when receiving a message ($`m`$, $`C`$) from $`P_j`$:

$` C_i[i,i] \gets C_i[i,i] + 1 `$

$` C_i[i,*] \gets max(C_i[i,*], C[i,*]) `$

$` for \space each \space k \space do: `$

$` \qquad C_i[k,*] \gets max(C_i[k,*], C[k,*]) `$

$` endfor `$

### Functions and details

If you want more details on the code, please checkout the comments made in the code itself. 

I've detailed every single one with:
- what it does,
- how it works, and
- how to use it.

<br/>

## Assignment (FR)

L'objectif de ce mini-projet est d'impl??menter en Erlang l'estampillage matricielle vu en cours et en TD, afin de synchroniser la communication au sein d'un ensemble de processus distribu??s.

On consid??re un ensemble de N processus (N ??tant param??trable), munis d'horloges matricielles. Chaque fois qu'un processus ??met/re??oit un message vers/en provenance des autres processus, il applique le m??canisme de mise ?? jours et de v??rification d'horloge matricielle vu en cours.

On vous demande d'impl??menter une communication entre ces N processus, chaque processus pouvant envoyer un ?? plusieurs messages ?? tous les autres processus.

Afin de tester votre programme, ce module comportera une fonction 'test' qui permettra de lancer la communication de messages entre N processus.

L'affichage dans le terminal devra tracer de fa??on tr??s lisible les estampilles des messages ??chang??s, et les mises ?? jour des horloges vectorielles des N processus.
