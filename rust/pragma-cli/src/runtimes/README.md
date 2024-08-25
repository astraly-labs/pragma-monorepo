# Supported Runtimes

* Sharingan

TODO: Improve the runtimes implementation without the need of replicating
the same functions for each runtime. Note that _RuntimeApi_ is runtime
specific. It gives access to api functions specific for each runtime.

## Generated files from subxt-cli

Download metadata from a substrate node, for use with `subxt` codegen.

```bash
subxt metadata --url ws://127.0.0.1:9944 -f bytes > madara_metadata.scale
```

Generate runtime API client code from metadata.

```bash
subxt codegen --url ws://127.0.0.1:9944 | rustfmt --edition=2018 --emit=stdout > madara_metadata.rs
```
