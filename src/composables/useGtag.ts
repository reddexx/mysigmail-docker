export function useGtag() {
  function gtag(..._args: any[]) {
    // noop analytics in CI / local build
    return undefined
  }

  return { gtag }
}
