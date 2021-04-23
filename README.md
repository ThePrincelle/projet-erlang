# Erlang project

Module simulating processes exchanging messages with matrix clocks

Author: Maxime Princelle

<br/>

**Table of contents:**

[[_TOC_]]

<br/>

## How to make it work?

xxx

## Automated testing

xxx

## How does it work?

### Rules

Here, we present a list of rules for each event when we use matrix clocks.

#### Local progress rule

before producing an internal event:

$` C_i[i,i] \gets C_i[i,i] +  1 `$

#### Sending rule

when sending a message $`m`$ to $`P_j`$:

$` C_i[i,i] \gets C_i[i,i] + 1 `$

$` send(m, C_i) \space to \space P_j `$

#### Receiving rule

when receiving a message ($`m`$, $`C`$) from $`P_j`$:

$` C_i[i,i] \gets C_i[i,i] + 1 `$

$` C_i[i,*] \gets max(C_i[i,*], C[i,*]) `$

$` for \space each \space k \space do: `$

$` \quad C_i[k,*] \gets max(C_i[k,*], C[k,*]) `$

$` endfor `$

## Sujet

L'objectif de ce mini-projet est d'implémenter en Erlang l'estampillage matricielle vu en cours et en TD, afin de synchroniser la communication au sein d'un ensemble de processus distribués.

On considère un ensemble de N processus (N étant paramétrable), munis d'horloges matricielles. Chaque fois qu'un processus émet/reçoit un message vers/en provenance des autres processus, il applique le mécanisme de mise à jours et de vérification d'horloge matricielle vu en cours.

On vous demande d'implémenter une communication entre ces N processus, chaque processus pouvant envoyer un à plusieurs messages à tous les autres processus.

Afin de tester votre programme, ce module comportera une fonction 'test' qui permettra de lancer la communication de messages entre N processus.

L'affichage dans le terminal devra tracer de façon très lisible les estampilles des messages échangés, et les mises à jour des horloges vectorielles des N processus.