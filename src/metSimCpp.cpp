#include <Rcpp.h>
using namespace Rcpp;

// [[Rcpp::export]]
IntegerVector get_constrained_indices_cpp(IntegerVector doy, IntegerVector hod, int day_win, int hour_win) {
  int n = doy.size();
  int max_doy = 366;
  int max_hour = 24;

  // 1. Create the Grid (3D Vector)
  // grid[day][hour] = {list of indices}
  std::vector<std::vector<std::vector<int>>> grid(max_doy + 1, std::vector<std::vector<int>>(max_hour));

  for(int i = 0; i < n; ++i) {
    int d = doy[i];
    int h = hod[i];
    grid[d][h].push_back(i + 1); // Store 1-based index
  }

  // 2. Iterate through each observation
  IntegerVector result(n);

  for(int i = 0; i < n; ++i) {
    int current_d = doy[i];
    int current_h = hod[i];

    std::vector<int> candidates;

    // Loop dynamically based on the provided window arguments
    for(int d_offset = -day_win; d_offset <= day_win; ++d_offset) {
      for(int h_offset = -hour_win; h_offset <= hour_win; ++h_offset) {

        // --- Handle Circular Wrapping ---

        // Day Wrap (1 to 366)
        int search_d = current_d + d_offset;
        // Handle multiple wraps if window > 366 (rare but safer logic)
        while (search_d > 366) search_d -= 366;
        while (search_d < 1)   search_d += 366;

        // Hour Wrap (0 to 23)
        int search_h = current_h + h_offset;
        while (search_h >= 24) search_h -= 24;
        while (search_h < 0)   search_h += 24;

        // --- Collect Indices ---
        const std::vector<int>& bucket = grid[search_d][search_h];
        if (!bucket.empty()) {
          candidates.insert(candidates.end(), bucket.begin(), bucket.end());
        }
      }
    }

    // 3. Sample one randomly
    if (candidates.size() > 0) {
      int rand_pos = floor(R::runif(0, candidates.size()));
      result[i] = candidates[rand_pos];
    } else {
      result[i] = NA_INTEGER;
    }
  }

  return result;
}
