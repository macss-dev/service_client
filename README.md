# service_client

Multi-language service client SDK with the Result pattern.  
Transport-agnostic interface with an HTTP implementation — available in Dart, TypeScript, and Python.

Part of the [MACSS](https://github.com/macss-dev/macss-dev) ecosystem.

---

## Packages

| Language   | Package                  | Registry                                                                 | Status      |
|------------|--------------------------|--------------------------------------------------------------------------|-------------|
| Dart       | `service_client`         | [pub.dev](https://pub.dev/packages/service_client)                       | v0.2.0      |
| TypeScript | `@macss/service-client`  | [npm](https://www.npmjs.com/package/@macss/service-client)               | Scaffold    |
| Python     | `macss-service-client`   | [PyPI](https://pypi.org/project/macss-service-client/)                   | Scaffold    |

---

## Repository structure

```
service_client/
├── code/
│   ├── dart/        ← Dart SDK (pub.dev)
│   ├── ts/          ← TypeScript SDK (npm)
│   ├── py/          ← Python SDK (PyPI)
│   └── tests/       ← Cross-language parity fixtures
├── docs/            ← Ecosystem documentation
├── LICENSE
└── README.md
```

---

## Documentation

- [Architecture](docs/architecture.md)
- [Roadmap](docs/roadmap.md)

---

## License

MIT © [ccisne.dev](https://ccisne.dev)