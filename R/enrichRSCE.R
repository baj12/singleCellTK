#' enrichR
#' Given a list of genes this function runs the enrichR() to perform Gene
#' enrichment
#'
#' @param inSCE Input SCtkExperiment object. Required
#' @param useAssay The assay to use in the enrichment analysis. Required
#' @param glist selected genes for enrichment analysis using enrichR(). Required
#' @param db selected database name from the enrichR database list.
#'
#' @return enrichRSCE(): returns a data.frame of enrichment terms overlapping in
#' the respective databases along with p-values, z-scores etc.,
#' @export
#'
#' @examples
#' enrichRSCE(mouseBrainSubsetSCE, "counts", "Cmtm5",
#'            "GO_Cellular_Component_2017")
#'
enrichRSCE <- function(inSCE, useAssay, glist, db = NULL){
  internetConnection <- suppressWarnings(Biobase::testBioCConnection())
  #check for internet connection
  if (!internetConnection){
    stop("Please connect to the Internet and continue..")
  }

  enrdb <- enrichR::listEnrichrDbs()$libraryName

  if (!(class(inSCE) == "SingleCellExperiment" |
        class(inSCE) == "SCtkExperiment")){
    stop("Please use a singleCellTK or a SCtkExperiment object")
  }

  #test for assay existing
  if (!all(useAssay %in% names(assays(inSCE)))){
    stop("assay '", useAssay, "' does not exist.")
  }

  #test for gene list existing
  if (!all(glist %in% rownames(inSCE))){
    stop("Gene in gene list not found in input object.")
  }

  #test for db existing
  if (!all(db %in% enrdb)){
    stop("database '", db, "' does not exist.")
  }

  if (is.null(glist)){
    stop("Please provide a gene list.")
  } else {
    if (is.null(db)){
      db <- enrdb
    }
    enriched <- enrichR::enrichr(glist, db)
    enriched <- data.frame(data.table::rbindlist(enriched, use.names = TRUE,
                                                 fill = TRUE,
                                                 idcol = "Database_selected"))
    temp_db <- enrichR::listEnrichrDbs()
    enriched$link <- sapply(enriched$Database_selected, function(x){
      temp_db$link[which(temp_db$libraryName %in% x)]
    })

    #sort the results based on p-values
    enriched <- enriched[base::order(enriched$P.value, decreasing = FALSE), ]

    #round the numeric values to their 7th digit
    nums <- base::vapply(enriched, is.numeric, FUN.VALUE = logical(1))
      enriched[, nums] <- base::round(enriched[, nums], digits = 7)
  }
  return(enriched)
}
