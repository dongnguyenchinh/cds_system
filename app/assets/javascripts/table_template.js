$(document).ready(function () {
  loadSlotsinCompetency();
  checkSlotinTemplate(1);
  var table = $('#table_slot').DataTable({
    "info": false, //không hiển thị số record / tổng số record
    "searching": false,
    "order": [[0, 'asc']]
  });
  $(".btnUp").click(function () {
    var id = $(this).closest('tr').attr('value');
    moveRowbyAjax(-1);
  });
  $(".btnDown").click(function () {
    var id = $(this).closest('tr').attr('value');
    moveRowbyAjax(1);
  });
  $('#selectCompetency').change(function () {
    loadSlotsinCompetency();
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
      addNewSlot(desc,evidence,level,competencyId,nameCompetency);
    else
      updateSlot(desc,evidence,level,competencyId,presentId);
    $("#descSlot").val("");
    $("#evidenceSlot").val("");
    loadSlotsinCompetency();
    changeBtnSave("-1")
    checkSlotinTemplate(1)
  });
  $("#tbdTemplate").on('click', '.btnDel', function () {
    var id = $(this).attr('value');
    var tr = $(this).closest('tr'); //loại bỏ hàng đó khỏi UI
    delSlot(id,tr);
  });
  $("#tbdTemplate").on('click', '.btnEdit', function () {
    var id = $(this).attr('value');
    var tr = $(this).closest('tr').children();
    $("#descSlot").val(tr[1].textContent);
    $("#evidenceSlot").val(tr[2].textContent);
    chooseSelect("selectLevel",tr[0].textContent);
    $("#hideIdSlot").html(id); //xóa id ẩn 
    checkSlotinTemplate(1);
  });
  changeBtnSave("-1");
  $("#table_slot").removeClass("dataTable")
  $('.dataTables_length').attr("style", "display:none");
});
//--------------------------------------------------------
function loadSlotsinCompetency() {
  var id = $('#selectCompetency').val();
  $("#nameCompetency").html($('#selectCompetency option:selected').text() + "'s Slots");
  $.ajax({
    type: "GET",
    url: "/templates/load_slot",
    data: {
      id: id //truyền id competency
    },
    dataType: "json",
    success: function (response) {
      var table = $("#table_slot").dataTable();
      table.fnClearTable();
      $(response).each(
        function (i, e) { //duyet mang doi tuong
          table.fnAddData([
            "<td class='td_num'>" + e.level + "</td>", e.desc, e.evidence, "<td class='td_action'><button class='btn btn-light btnAction btnEdit' value='"+ e.id +"'><i class='fa fa-pencil icon' style='color:#FFCC99'></i></button>" +
            "<button class='btn btn-light btnAction btnDel' value='"+ e.id +"'><i class='fa fa-trash icon' style='color:red'></i></button><button class='btn btn-primary btnAction btnUp' ><i class='fa fa-arrow-circle-up icon'></i></button>" +
            "<button class='btn btn-primary btnAction btnDown'><i class='fa fa-arrow-circle-down icon'></i></button></td>"
          ]);
        }
      );
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

function moveRowbyAjax(direction) {
  $.ajax({
    type: "GET",
    url: "/templates/moveTemplate",
    data: {
      id: id,
      direction: direction //direction phân biệt up hay down để change data cho phù hợp
    },
    dataType: "json",
    success: function (response) {
      $(response).each(
        function (i, e) { //duyet mang doi tuong
          loadDataSlot(); //load lại table sau khi up or down
        }
      );
    }
  });
}

function addNewSlot(desc,evidence,level,competencyId,nameCompetency) {
  $.ajax({
    type: "GET",
    url: "/templates/add_new_slot",
    data: {
      desc: desc,
      evidence: evidence,
      level: level,
      competency_id: competencyId
    },
    dataType: "json",
    success: function (response) {
      success("Add new slot to " + nameCompetency + " is ");
      loadSlotsinCompetency();
    },
    error: function () {
      fails("Add new slot to " + nameCompetency + " is ");
    }
  });
}

function updateSlot(desc,evidence,level,competencyId,presentId) {
  $.ajax({
    type: "GET",
    url: "/templates/update_slot",
    data: {
      desc: desc,
      evidence: evidence,
      level: level,
      competency_id: competencyId,
      id: presentId
    },
    dataType: "json",
    success: function (response) {
      success("Update slot is ");
      loadSlotsinCompetency();
    },
    error: function () {
      fails("Update slot is ");
    }
  });
}

function delSlot (id,tr){
  bootbox.confirm({
		message: "Are you sure want to delete this slot?",
		buttons: {
			confirm: {
				label: "Yes",
				className: "btn-primary"
			},
			cancel: {
				label: "No",
				className: "btn-danger"
			}
		},
		callback: function (result) {
			if (result) {
				$.ajax({
					url: "/templates/delete_slot",
					data: {
            id: id
					},
					type: "GET",
					success: function (response) {
            success("Delete slot is");
            $("#table_slot").dataTable().fnDeleteRow(tr);
            checkSlotinTemplate(1); //check lại button Finnish
					},
					error: function () {
						fails("Delete slot is");
					}
				});
			}
		}
	});
}
function  changeBtnFinish(direction) {
  if(direction == "-1")
  {
    $("#btnFinish").attr("disabled", true);
    $("#btnFinish").removeClass("btn-primary").addClass("btn-secondary")
  }
  else
  {
    $("#btnFinish").attr("disabled", false);
    $("#btnFinish").addClass("btn-primary").removeClass("btn-secondary")
  }
}
function  changeBtnSave(direction) {
  if(direction == "-1")
  {
    $("#addSlot").attr("disabled", true);
    $("#addSlot").removeClass("btn-primary").addClass("btn-secondary")
  }
  else
  {
    $("#addSlot").attr("disabled", false);
    $("#addSlot").addClass("btn-primary").removeClass("btn-secondary")
  }
}
function checkSlotinTemplate (templateId){
  $.ajax({
    type: "GET",
    url: "/templates/check_slot_in_template",
    data: {
      template_id: templateId
    },
    dataType: "json",
    success: function (response) {
      changeBtnFinish(response);
    }
  });
}
function chooseSelect(nameSelect,value) {
  $("#"+ nameSelect).each(function(){ 
    $(this).find('option[value="'+ value +'"]').prop('selected', true); 
  });
}
function checkInputData() {
  if($("#evidenceSlot").val() != "" && $("#descSlot").val() != "")
  {
    changeBtnSave("1")
  }
  else{
    changeBtnSave("-1")
  }
}