## 0.6.0
* Raise `UnknownRepoError` if the registry returns the `NAME_UNKNOWN` error code, which indicates the repo has never been pushed to before.

## 0.5.1
* Just use given port if present, i.e. without checking it for connectivity.

## 0.5.0
* Figure out registry port more accurately.

## 0.4.0
* Support redirection when making HTTP requests.

## 0.3.0
* Support registries with no auth.
* Raise errors upon receiving unexpected response codes during auth flow.

## 0.2.0
* Support both basic and bearer auth.

## 0.1.0
* Birthday!
