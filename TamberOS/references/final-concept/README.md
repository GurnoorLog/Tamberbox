# Official TamberOS final concepts — originals required

The user designated **01-bootloader-concept.png**, featuring the sunglasses llama,
as the official visual reference for the future boot experience. It must not be
replaced with a generic crown/splash, a recreation, or another generated image.

The nine original PNGs are absent from the starter ZIP available in this session.
No placeholder PNGs have been created. This gate remains blocked until the updated
starter ZIP containing `references/final-concept/` is provided.

Import those exact bytes with:

```sh
python3 scripts/import_concepts.py /path/to/updated-starter.zip
python3 scripts/check_assets.py --require-final-concepts
```

The importer accepts only nine PNGs numbered 01–09 with the required boot filename,
records the source archive hash and each image hash, and refuses to overwrite a
different existing concept. Review the images after import. The preservation check
also protects the original SVG mascot, crown, logo and supplied poster.
