$(document).ready(function () {
  var templateId = $('#msform .row .id-template').attr("value")
  checkSlotinTemplate(templateId);
  $('#table_slot').DataTable({
    fnDrawCallback: function(){checkPrivileges_step3(); disableButtonUpDown();}, //; 
    "info": false, //không hiển thị số record / tổng số record
    "searching": false,
    "order": [
      [0, 'asc']
    ]
  });
  $('#selectCompetency').change(function () {
    loadSlotsinCompetency();
    $("#selectLevel").val($("#selectLevel option:first").val());
  });
  $("#addSlot").click(function () {
    var desc = $("#descSlot").val();
    var evidence = $("#evidenceSlot").val();
    var level = $("#selectLevel").val();
    var competencyId = $("#selectCompetency").val();
    var nameCompetency = $("#selectCompetency option:selected").text();
    var presentId = $("#hideIdSlot").html();
    $("#hideIdSlot").html("");
    if (presentId == "")
      addNewSlot(desc, evidence, level, competencyId, nameCompetency, templateId);
    else
      updateSlot(desc, evidence, level, competencyId, presentId, templateId);
    $("#descSlot").val("");
    $("#evidenceSlot").val("");
    loadSlotsinCompetency();
    changeBtnSave(-1)
  });
  var trDel;
  var idDel;
  $("#table_slot").on('click', '.btnDel', function () {
    idDel = $(this).attr('value');
    trDel = $(this).closest('tr'); //loại bỏ hàng đó khỏi UI
    $('#contentMessageDelete').html("Are you sure you want to delete the slot below?<p><i>" + trDel.children()[1].textContent + "</i></p>")
    $("#messageDelete").modal('show')
  });
  $("#btnDelete").click(function(){
    delSlot(idDel, trDel, templateId);
    $("#hideIdSlot").html("");
    $("#descSlot").val("");
    $("#evidenceSlot").val("")
    $("#messageDelete").modal('hide')
    $('#contentMessageDelete').html("")
  })

  $("#table_slot").on('click', '.btnEdit', function () {
    var id = $(this).attr('value');
    var tr = $(this).closest('tr').children();
    $("#descSlot").val(tr[1].textContent);
    $("#evidenceSlot").val(tr[2].textContent);
    chooseSelect("selectLevel", tr[0].textContent);
    $("#hideIdSlot").html(id);
  });
  changeBtnSave(-1);
  $("#table_slot").removeClass("dataTable")
  $('.dataTables_length').attr("style", "display:none");

  $("#btnFinish").click(function () {
    if (checkStatusTemplate() == 0)
      $('#messageQuestionEnable').modal('show')
  })
  $('#btnEnable').click(function () {
    finnish(templateId);
    $('#messageQuestionEnable').modal('hide')
  })

  $("#txtSearch").keypress(function () {
    if (event.keyCode == 13 || event.which == 13) {
      var search = $(this).val();
      loadSlotsinCompetency(search)
    }
  })
  $("#descSlot").keyup(function () {
    if ($("#descSlot").val())
      $("#ErrorDesc").attr("style", "display:none")
    else
      $("#ErrorDesc").attr("style", "display:block")
  })
  $(".nexttoStep3").click(function () {
    templateId = $('#msform .row .id-template').attr("value")
    loadCompetency(templateId);
    checkStatusTemplate(templateId);
    $("#hideIdSlot").html("");
    $("#descSlot").val("");
    $("#evidenceSlot").val("")
    changeBtnSave(-1);
  });
  //-----------------------------------------------------
});
//--------------------------------------------------------
function loadSlotsinCompetency(search) {
  var id = $('#selectCompetency').val();
  $("#nameCompetency").html("  " + $('#selectCompetency option:selected').text() + " / Slot List");
  $.ajax({
    type: "GET",
    url: "/slots/load",
    data: {
      id: id, //truyền id competency
      search: search
    },
    dataType: "json",
    success: function (response) {
      var table = $("#table_slot").dataTable();
      table.fnClearTable();
      $(response).each(
        function (i, e) { //duyet mang doi tuong
          if (search) {
            table.fnAddData([
              e.level, e.desc, e.evidence, "<a href='#' type='button' class='btnAction btnEdit' value='" + e.id + "'><i class='fa fa-pencil icon' style='color:#fc9803'></i></a>" +
              "<a class='btnAction btnDel' value='" + e.id + "'><i class='fa fa-trash icon' style='color:red'></i></a>"
            ], 0);
          } else {
            table.fnAddData([
              e.level, e.desc, e.evidence, "<a class='btnAction btnUpSlot' style='color:green' value='" + e.id + "'><i class='fa fa-arrow-circle-up icon'></i></a>" +
              "<a class='btnAction btnDownSlot' style='color:green' value='" + e.id + "'><i class='fa fa-arrow-circle-down icon'></i></a>" +
              "<a href='#' type='button'  class='btnAction btnEdit' value='" + e.id + "'><i class='fa fa-pencil icon' style='color:#fc9803'></i></a>" +
              "<a class='btnAction btnDel' value='" + e.id + "'><i class='fa fa-trash icon' style='color:red'></i></a>"
            ], 0);
          }
        }
      );
      table.fnDraw();
      disableButtonUpDown()
      checkPrivileges_step3()
    }
  });
}

//alert success
function success(content) {
  $('#content-alert-success').html(content);
  $("#alert-success").fadeIn();
  window.setTimeout(function () {
    $("#alert-success").fadeOut(1000);
  }, 5000);
}
// alert fails
function fails(content) {
  $('#content-alert-fail').html(content);
  $("#alert-danger").fadeIn();
  window.setTimeout(function () {
    $("#alert-danger").fadeOut(1000);
  }, 5000);
}


function addNewSlot(desc, evidence, level, competencyId, nameCompetency, templateId) {
  $.ajax({
    type: "GET",
    url: "/slots/new",
    data: {
      desc: desc,
      evidence: evidence,
      level: level,
      competency_id: competencyId
    },
    dataType: "json",
    success: function () {
      success("The slot has been saved successfully.");
      loadSlotsinCompetency();
      checkSlotinTemplate(templateId)
    },
    error: function (response) {
      fails("The slot hasn't been saved");
    }
  });
}

function updateSlot(desc, evidence, level, competencyId, presentId, templateId) {
  $.ajax({
    type: "GET",
    url: "/slots/update",
    data: {
      desc: desc,
      evidence: evidence,
      level: level,
      competency_id: competencyId,
      id: presentId
    },
    dataType: "json",
    success: function (response) {
      success("The slot has been updated successfully.");
      loadSlotsinCompetency();
      checkSlotinTemplate(templateId)
    },
    error: function () {
      fails("The slot hasn't been updated");
    }
  });
}

function delSlot(id, tr, templateId) {
  $.ajax({
    url: "/slots/delete",
    data: {
      id: id
    },
    type: "GET",
    success: function (response) {
      success("The slot has been deleted successfully.");
      $("#table_slot").dataTable().fnDeleteRow(tr);
      checkSlotinTemplate(templateId)
      disableButtonUpDown()
    },
    error: function () {
      fails("The slot hasn't been deleted");
    }
  });
}

function changeBtnFinish(direction) {
  if (checkStatusTemplate() == 1) {
    $("#btnFinish").attr("disabled", true);
    $("#btnFinish").removeClass("btn-primary").addClass("btn-secondary")
  } else {
    if (direction == -1) {
      $("#btnFinish").attr("disabled", true);
      $("#btnFinish").removeClass("btn-primary").addClass("btn-secondary")
    } else {
      $("#btnFinish").attr("disabled", false);
      $("#btnFinish").addClass("btn-primary").removeClass("btn-secondary")
    }
  }
}

function changeBtnSave(direction) {
  if (direction == -1) {
    $("#addSlot").attr("disabled", true);
    $("#addSlot").removeClass("btn-primary").addClass("btn-secondary")
  } else {
    $("#addSlot").attr("disabled", false);
    $("#addSlot").addClass("btn-primary").removeClass("btn-secondary")
  }
}

function checkSlotinTemplate(templateId) {
  $.ajax({
    type: "GET",
    url: "/slots/check_slot_in_template",
    data: {
      template_id: templateId
    },
    dataType: "json",
    success: function (response) {
      changeBtnFinish(parseInt(response));
    }
  });
}

function chooseSelect(nameSelect, value) {
  $("#" + nameSelect).each(function () {
    $(this).find('option[value="' + value + '"]').prop('selected', true);
  });
}

function checkDataDesc() {
  if ($("#descSlot").val())
    changeBtnSave(1)
  else
    changeBtnSave(-1)
}

function finnish(templateId) {
  $.ajax({
    type: "GET",
    url: "/slots/update_status_template",
    data: {
      template_id: templateId
    },
    dataType: "json",
    success: function (response) {
      $("#contentMessageEnable").html("Enable Successfully")
      $("#messageEnable").modal('show')
      changeBtnFinish(-1)
    },
    error: function () {
      $("#contentMessageEnable").html("Can't Enable This Template!")
      $("#messageEnable").modal('show')
    }
  });
}
$(document).on('click', '.btnUpSlot', function () {
  var row_id = $(this).closest('tr').index();
  var id = $(this).attr('value');
  table = $("#table_slot").DataTable();
  moveRow(id, row_id, -1, table);
});
$(document).on('click', '.btnDownSlot', function () {
  var row_id = $(this).closest('tr').index();
  var id = $(this).attr('value');
  table = $("#table_slot").DataTable();
  moveRow(id, row_id, 1, table)
});

function moveRow(id, row_id, direction, table) {
  $.ajax({
    type: "GET",
    url: "/slots/change_slot_id",
    headers: {
      "X-CSRF-Token": $('meta[name="csrf-token"]').attr("content"),
    },
    data: {
      id: id,
      direction: direction
    },
    dataType: "json",
    success: function (response) {
      if (response.status != "success")
      {
        $("#contentMessageMove").html("This slot is belonging to level "+ response.status +". Therefore, you cannot move it to another level. Please update its level before doing this action.")
        $('#messageMove').modal('show')
      }
      else {
        success("Move success");
        var num = parseInt(direction);
        current_row_data = table.row(row_id).data();
        previous_row_data = table.row(row_id + num).data();

        table.row(row_id + num).data(current_row_data).draw();
        table.row(row_id).data(previous_row_data).draw();
        disableButtonUpDown()
      }
    },
    error: function () {
      fails("Move fail");
    }
  });
}

function loadCompetency(templateId) {
  $.ajax({
    type: "GET",
    url: "/slots/load_competency",
    data: {
      template_id: templateId
    },
    dataType: "json",
    success: function (response) {
      $("#selectCompetency").html("");
      $(response).each(
        function (i, e) { //duyet mang doi tuong
          $("<option value='" + e.id + "'/>").html(e.name).appendTo("#selectCompetency");
        });
      loadSlotsinCompetency();
      checkSlotinTemplate(templateId);
    }
  });
}

function checkStatusTemplate() {
  if ($('#msform .row .status-template').attr("value") == "true")
    return 1
  else
    return 0
}
function disableButtonUpDown(){
  // resetButton();
  // tables = $("#table_slot").DataTable();
  // length = tables.rows().data().length;
  // if (length >= 1) {
  //   $('#table_slot tr:nth-child(1) td .btnUpSlot .icon').attr('style','color:#6c757d')
  //   $('#table_slot tr:nth-child(1) td .btnUpSlot').addClass('disabled')
  //   $('#table_slot tr:nth-child('+length+') td .btnDownSlot .icon').attr('style','color:#6c757d')
  //   $('#table_slot tr:nth-child('+length+') td .btnDownSlot').addClass('disabled')
  // }
}
function checkPrivileges_step3(){
  $.ajax({
    type: "GET",
    url: "/competencies/check_privileges",
    headers: {
      "X-CSRF-Token": $('meta[name="csrf-token"]').attr("content"),
    },
    data: {},
    dataType: "json",
    success: function (response) {
      if (response.privileges == "view"){
        $('#tbdTemplate tr td a').addClass("disabled");
        $("#tbdTemplate tr td .fa-arrow-circle-up,.fa-arrow-circle-down,.fa-trash,.fa-pencil").css("color", "#6c757d");
        $('#selectLevel').prop("disabled", true);
        $('#descSlot').prop("disabled", true);
        $('#evidenceSlot').prop("disabled", true);
        $("#btnFinish").attr("disabled", true);
        $("#btnFinish").removeClass("btn-primary").addClass("btn-secondary")
      }
    },
  });
}
function resetButton ()
{
  $('#tbdTemplate tr td a').removeClass("disabled");
  $('#table_slot tr:nth-child(1) td .btnDownSlot .icon').attr('style','color:green')
  $('#table_slot tr:nth-child(1) td .btnUpSlot .icon').attr('style','color:green')
}