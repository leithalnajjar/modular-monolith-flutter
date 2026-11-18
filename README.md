# Modular Monolith in Flutter: companion code

The complete code of the book *Modular Monolith in Flutter* by Leith Al-Najjar
(series: Modular Monolith in Practice, book 1).

| Folder | What it is |
|---|---|
| `bazaar/` | Bazaar, the sample app built through the book: two apps, six modules, the shared packages and `tools/boundary_check` |
| `legacy_shop/` | The deliberately muddy app from Chapter 24, after its first module was carved out |

Appendix A of the book lists every file shown in the book and the chapters that show it.

## Requirements

Flutter 3.50 or later (Dart 3.14). Pub workspaces need at least Dart 3.6; the code imports Material from the `material_ui` package (Flutter 3.47 and later).

## Run everything

```bash
cd bazaar
flutter pub get
dart run tool/check.dart        # analyzer, boundary check, docs, every package's tests
```

Useful commands from the book:

```bash
dart run boundary_check                    # the boundary rules (Chapter 18)
dart run boundary_check:affected <files>   # packages a change can affect (Chapter 22)
dart run boundary_check:modules            # the module map (Chapter 22)
dart run boundary_check:metrics            # migration metrics (Chapter 24)
cd apps/bazaar_app && flutter run          # the shopping app (demo sign-in: demo@bazaar.dev / bazaar123)
```

## License

The code is released under the MIT License (see `LICENSE`). The book's text is not included and remains under copyright.
