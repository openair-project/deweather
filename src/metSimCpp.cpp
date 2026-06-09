#include <Rcpp.h>
using namespace Rcpp;

// Shared helper: build a (day, hour) → row-index grid from doy/hod vectors.
static std::vector<std::vector<std::vector<int>>>
build_grid(const IntegerVector& doy, const IntegerVector& hod) {
  int n = doy.size();
  std::vector<std::vector<std::vector<int>>> grid(367, std::vector<std::vector<int>>(24));
  for (int i = 0; i < n; ++i)
    grid[doy[i]][hod[i]].push_back(i + 1); // 1-based
  return grid;
}

// Shared helper: collect candidate row indices for observation i.
static std::vector<int>
build_candidates(int current_d, int current_h, int day_win, int hour_win,
                 const std::vector<std::vector<std::vector<int>>>& grid) {
  std::vector<int> candidates;
  for (int d_off = -day_win; d_off <= day_win; ++d_off) {
    int sd = current_d + d_off;
    while (sd > 366) sd -= 366;
    while (sd < 1)   sd += 366;
    for (int h_off = -hour_win; h_off <= hour_win; ++h_off) {
      int sh = current_h + h_off;
      while (sh >= 24) sh -= 24;
      while (sh < 0)   sh += 24;
      const auto& b = grid[sd][sh];
      candidates.insert(candidates.end(), b.begin(), b.end());
    }
  }
  return candidates;
}

// [[Rcpp::export]]
IntegerVector get_constrained_indices_cpp(IntegerVector doy, IntegerVector hod,
                                          int day_win, int hour_win) {
  int n = doy.size();
  auto grid = build_grid(doy, hod);
  IntegerVector result(n);
  for (int i = 0; i < n; ++i) {
    auto cands = build_candidates(doy[i], hod[i], day_win, hour_win, grid);
    if (!cands.empty())
      result[i] = cands[floor(R::runif(0, cands.size()))];
    else
      result[i] = NA_INTEGER;
  }
  return result;
}

// Multi-simulation variant.  Returns an n_obs × n_sims integer matrix where
// column j holds simulation j's sampled row indices.
//
// Two key optimisations over calling get_constrained_indices_cpp n_sims times:
//
// 1. Candidate caching: the candidate pool for a given (doy, hod) pair is
//    identical across all observations that share that pair.  For a 20-year
//    hourly dataset there are at most 366×24 = 8 784 unique pairs, so we
//    build the pool once per pair rather than once per observation (up to
//    144 k / 8 784 ≈ 16× fewer builds).
//
// 2. Cache-friendly writes: the outer loop iterates over simulations and the
//    inner loop over observations, so result(i, s) for fixed s is written
//    sequentially in column-major (R) memory — no cache-line thrashing.
// [[Rcpp::export]]
IntegerMatrix get_constrained_indices_multi_cpp(IntegerVector doy, IntegerVector hod,
                                                int day_win, int hour_win, int n_sims) {
  int n = doy.size();
  auto grid = build_grid(doy, hod);

  // Build candidate pools for each unique (doy, hod) pair.
  const int CACHE_SIZE = 367 * 24;
  std::vector<std::vector<int>> cand_cache(CACHE_SIZE);
  std::vector<bool> computed(CACHE_SIZE, false);
  for (int i = 0; i < n; ++i) {
    int key = doy[i] * 24 + hod[i];
    if (!computed[key]) {
      cand_cache[key] = build_candidates(doy[i], hod[i], day_win, hour_win, grid);
      computed[key] = true;
    }
  }

  // Outer loop: simulations; inner loop: observations → column-major writes.
  IntegerMatrix result(n, n_sims);
  for (int s = 0; s < n_sims; ++s) {
    for (int i = 0; i < n; ++i) {
      const auto& cands = cand_cache[doy[i] * 24 + hod[i]];
      int nc = cands.size();
      result(i, s) = nc > 0 ? cands[(int)R::runif(0, nc)] : NA_INTEGER;
    }
  }
  return result;
}
