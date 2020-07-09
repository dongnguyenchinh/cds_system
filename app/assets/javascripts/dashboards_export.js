function callAjaxExport(url, ext) {
  temp_params = Object.assign({},data_filter);
  temp_params["ext"] = ext;
  $.ajax({
    url: url,
    data: temp_params,
    type: "POST",
    headers: {
      "X-CSRF-Token": $('meta[name="csrf-token"]').attr("content")
    },
    success: function (response) {
      // download this file in NEW TAB
      if (response.file_path == "") {
        alert("File is empty!");
      } else {
        window.open("/" + response.file_path, '_blank');
      }
    }
  });
}

$("#export_excel_up_title").on('click', function () {
  callAjaxExport("/dashboards/export_up_title", "xlsx");
});

$("#export_pdf_up_title").on('click', function () {
  callAjaxExport("/dashboards/export_up_title", "pdf");
});

$("#export_excel_down_title").on('click', function () {
  callAjaxExport("/dashboards/export_down_title", "xlsx");
});

$("#export_pdf_down_title").on('click', function () {
  callAjaxExport("/dashboards/export_down_title", "pdf");
});

$("#export_excel_keep_title").on('click', function () {
  callAjaxExport("/dashboards/export_keep_title", "xlsx");
});

$("#export_pdf_keep_title").on('click', function () {
  callAjaxExport("/dashboards/export_keep_title", "pdf");
});