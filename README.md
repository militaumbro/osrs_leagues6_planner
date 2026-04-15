# OSRS Leagues 6 Planner

A task tracker for **Old School RuneScape Leagues 6: Demonic Pacts**, built with Flutter and deployed as a web app.

## What it does

- Browse tasks organized by guide route and section
- Check off tasks as you complete them — progress is saved in your browser
- Switch between three community routes (**Doubleshine Day 1**, **Laef's wiki guide**, and **Faux's Day 1 guide**) with a tab bar
- Completion is **shared between routes**: checking a task in one route marks it in the other if the task appears in both
- Search tasks or sections by name
- Adjust font size of the task list independently from the rest of the UI
- Sort pending tasks to the top within any section

## Routes included

| Route | Source |
|---|---|
| Doubleshine | Doubleshine's Leagues 6 Day 1 community guide |
| Laef | [Laef's Demonic Pacts starting guide](https://oldschool.runescape.wiki/w/Guide:Leagues:_Demonic_pacts_starting_guide_by_Laef) on the OSRS Wiki |
| Faux | [Faux's Demonic Pact League Guide](https://youtu.be/Job-3WdjVIs) (181 tasks, 3300+ pts) |

## Live site

**https://militaumbro.github.io/osrs_leagues6_planner/**

## Running locally

Requires [Flutter](https://flutter.dev) SDK.

```bash
flutter pub get
flutter run -d windows   # desktop
flutter run -d chrome    # web
```
