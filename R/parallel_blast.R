#' @title Run BLAST on parallel
#'
#' @description Run parallel BLAST for set of sequences
#'
#' @inheritParams get_blast_results
#'
#' @param asvs Character vector with sequences
#' @param out_file Complete path to output .csv file on an existing folder.
#' @param out_RDS Complete path to output RDS file on an existing folder.
#' @param total_cores Total available cores to run BLAST in parallel. Check your max with *future::availableCores()*
#' @param blast_type BLAST+ executable to be used on search.
#'
#' @return A tibble with the BLAST tabular output.
#'
#' @examples
#' \dontrun{
#' blast_res <- BLASTr::parallel_blast(
#'   asvs = ASVs_test, # vector of sequences to be searched
#'   db_path = "/data/databases/nt/nt", # path to a formatted blast database
#'   out_file = NULL, # path to a .csv file to be created with results (on an existing folder)
#'   out_RDS = NULL, # path to a .RDS file to be created with results (on an existing folder)
#'   perc_id = 80, # minimum identity percentage cutoff
#'   perc_qcov_hsp = 80, # minimum percentage coverage of query sequence by subject sequence cutoff
#'   num_threads = 1, # number of threads/cores to run each blast on
#'   total_cores = 8, # number of total threads/cores to allocate all blast searches
#'   # maximum number of alignments/matches to retrieve results for each query sequence
#'   num_alignments = 3,
#'   blast_type = "blastn" # blast search engine to use
#' )
#' }
#' @export
parallel_blast <- function(asvs,
                           db_path,
                           out_file = NULL,
                           out_RDS = NULL,
                           num_threads = 1L,
                           blast_type = "blastn",
                           total_cores = 1L,
                           # gapopen = gapopen,
                           # gapextend = gapextend,
                           # task = task,
                           perc_id = 80L,
                           perc_qcov_hsp = 80L,
                           num_alignments = 4L,
                           verbose = FALSE,
                           env_name = "blast-env") {
  rlang::check_required(asvs)
  rlang::check_required(db_path)
  # rlang::check_required(out_file)
  # rlang::check_required(out_RDS)

  # TODO: Convert ASVs to vector, if needed


  # if (is.null(db_path)) {
  #   db_path <- getOption(
  #     "BLASTr.db_path",
  #     default = NULL
  #   )
  # }
  # if (is.null(db_path)) {
  #   cli::cli_abort(
  #     message = "No BLAST database provided."
  #   )
  # }
  # if (is.null(num_thread)) {
  #   num_thread <- getOption(
  #     "BLASTr.num_thread",
  #     default = 1
  #   )
  # }
  check_cmd(blast_type, env_name = env_name, verbose = verbose)

  if (total_cores > 1) {
    future::plan(future::multisession(),
      workers = total_cores
    )

    blast_res <- furrr::future_map_dfr(
      .x = asvs,
      .f = get_blast_results,
      .options = furrr::furrr_options(seed = NULL),
      # .progress = TRUE,
      num_threads = 1,
      blast_type = blast_type,
      num_alignments = num_alignments,
      # gapopen = 5,
      # gapextend = 2,
      # task = task,
      db_path = db_path,
      perc_id = perc_id,
      perc_qcov_hsp = perc_qcov_hsp,
      verbose = verbose
    )
  } else {
    blast_res <- purrr::map_dfr(
      .x = asvs,
      .f = get_blast_results,
      # .progress = TRUE,
      num_threads = 1,
      blast_type = blast_type,
      num_alignments = num_alignments,
      # gapopen = 5,
      # gapextend = 2,
      # task = task,
      db_path = db_path,
      perc_id = perc_id,
      perc_qcov_hsp = perc_qcov_hsp,
      verbose = verbose
    )
  }

  if (isTRUE(!is.na(out_file) && !is.null(out_file))) {
    readr::write_csv(
      x = blast_res,
      file = out_file,
      append = FALSE
    )
  }

  if (isTRUE(!is.na(out_RDS) && !is.null(out_RDS))) {
    readr::write_rds(
      x = blast_res,
      file = out_RDS
    )
  }

  # Reset future plan to default
  if (total_cores > 1L) {
    future::plan(future::sequential)
  }

  return(blast_res)
}
