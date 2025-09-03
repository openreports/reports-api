# Release docs

This doc contains information for releasing a new version.

## Create a release

Creating a release can be done by pushing a tag to the GitHub repository (beginning with `v`).

The [release workflow](../../.github/workflows/release.yaml) will take care of creating the GitHub release and will publish artifacts.

```shell
VERSION="v0.2.0-alpha.1"
TAG=$VERSION

git tag $TAG -m "tag $TAG" -a
git push origin $TAG
```
