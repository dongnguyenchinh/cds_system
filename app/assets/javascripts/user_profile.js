$(document).ready(function () {
  var start_date = new Date(Date.parse(01-01-1945));
  var end_date = new Date();
  end_date.setDate(end_date.getDate()-(365*16));
  $("#birthday").datepicker({
    todayBtn: "linked",
    todayHighlight: true,
    startDate: start_date,
    endDate: end_date,
    autoclose: true,
    format: "M dd, yyyy"
  })
  $("#edit_contact").click(function () {
    $("#modal_edit_contact").modal("show");
  })
  $(".cancel-edit-user-profile").click(function () {
    setTimeout(location.reload.bind(location), 100);
  })
  $("#change_avatar").on('change', function () {
    var file = this.files[0]
    $.ajax({
      type: "POST",
      url: "/users/edit_user_avatar",
      data: file,
      headers: {
        "X-CSRF-Token": $('meta[name="csrf-token"]').attr("content")
      },
      success: function (response) {
        if (response) {
          warning("Your avatar have been updated successfully!")
          $("avt").attr('src', url)
        } else
          fails("Your avatar haven't been updated!")
      }
    });
  })

  $("#edit_location").click(function () {
    $("#modal_edit_location").modal("show");
  })

  $("#change_password").click(function () {
    $("#old_pass").val('')
    $("#modal_change_password").modal("show");
  })

  $(".btn-save-edit").click(function () {
    var provinces = $("#provinces option:selected").val() == "" ? "" : $("#provinces option:selected").text()
    var permanent_address = $("#district option:selected").val() + ", " + provinces
    var h_user = {
      id: $("#user_id").val(),
      first_name: $("#first_name").val(),
      last_name: $("#last_name").val(),
      phone_number: $("#phone_number").val(),
      date_of_birth: $("#birthday").val(),
      gender: $("#gender").val(),
      skype: $("#skype").val(),
      nationality: $("#nationality").val(),
      permanent_address: permanent_address,
      current_address: $("#current_address").val()
    }
    $.ajax({
      type: "POST",
      url: "/users/edit_user_profile",
      data: h_user,
      headers: {
        "X-CSRF-Token": $('meta[name="csrf-token"]').attr("content")
      },
      dataType: "json",
      success: function (response) {
        if (response) {
          $("#modal_edit_contact").modal("hide")
          $("#modal_edit_location").modal("hide")
          warning("Your profile have been updated successfully!")
          setTimeout(location.reload.bind(location), 1000);
        } else
          fails("Your profile haven't been updated!")
      }
    });
  })

  $("#btn_change_password").click(function () {
    changeBtnSave("btn_change_password", false)
    if (checkEmptyData()) {
      $.ajax({
        type: "POST",
        url: "/users/change_password",
        data: {
          id: $("#user_id").val(),
          old_password: $("#old_pass").val(),
          new_password: $("#new_pass").val(),
          confirm_password: $("#confirm_pass").val()
        },
        headers: {
          "X-CSRF-Token": $('meta[name="csrf-token"]').attr("content")
        },
        dataType: "json",
        success: function (response) {
          if (response.status == "success") {
            warning("Your password have been changed successfully!")
            $("#modal_change_password").modal("hide")
            setTimeout(location.reload.bind(location), 1000);
          } else if (response.status == "Uncorrect") {
            changeClassStatus($("#old_pass"))
            $("#error_old_pass").html("Please enter correct password!")
          } else if (response.status == "Unequal") {
            changeClassStatus($("#confirm_pass"))
            $("#error_confirm").html("Confirm password isn't equal new password!")
          } else
            fails("Could not changed password!")
        }
      });
    }
  })


  $("#modal_change_password #confirm_pass").keyup(function () {
    if ($(this).val() != $("#new_pass").val()) {
      $(this).addClass("is-invalid").removeClass("is-valid")
      $("#error_confirm").html("Confirm password isn't equal new password!")
    } else {
      $(this).addClass("is-valid").removeClass("is-invalid")
      $("#error_confirm").html("")
    }
    changeBtnSave("btn_change_password", true, true)
  })

  $("#modal_change_password #new_pass").keyup(function () {
    //var regex = /^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{6,}$/;
    var regex = /^(?=.*[A-Z])(?=.*[!@#$&*])(?=.*[0-9])(?=.*[a-z]).{8,32}$/;
    var pass = $(this).val()
    if (pass == "") {
      $(this).addClass("is-invalid").removeClass("is-valid")
      $("#error_new_pass").html("Please enter new password")
    } else if (!regex.test(pass)) {
      $(this).addClass("is-invalid").removeClass("is-valid")
      $("#error_new_pass").html("Min of 8 characters and must have: a uppercase, a downcase, a symbol, a number")
    } else {
      $(this).addClass("is-valid").removeClass("is-invalid")
      $("#error_new_pass").html("")
    }
    changeBtnSave("btn_change_password", true, true)
  })

  $("#old_pass").change(function () {
    var data = $(this).val()
    changeBtnSave("btn_change_password", true, true)
    if (data) {
      $(this).removeClass("is-invalid")
      $("#error_old_pass").html("")
    } else {
      $(this).addClass("is-invalid")
      $("#error_old_pass").html("Please enter old password")
    }
  })

  $("#first_name").keyup(function () {
    var first_name = $(this).val().trim()
    if (first_name) {
      checkDataContact()
      checkName(first_name, "first_name", "error_first_name")
    } else {
      $(this).addClass("is-invalid")
      $("#error_first_name").html("First name must be from 1 to 32 characters")
      changeBtnSave("btn_save_contact", false)
    }
  })
  $("#phone_number").keyup(function () {
    var phone_number = $(this).val().trim()
    if (phone_number) {
      checkDataContact()
      checkPhoneNumber(phone_number, "phone_number", "error_phone_number")
    } else {
      $(this).addClass("is-invalid")
      $("#error_phone_number").html("Please enter phone number")
      changeBtnSave("btn_save_contact", false)
    }
  })
  $("#birthday").change(function () {
    checkDataContact()
  })
  $("#gender").change(function () {
    checkDataContact()
  })
  $("#skype").keyup(function () {
    checkDataContact()
  })

  $(".show-pass").on('click', function () {
    $(this).closest('.row').find('input').prop('type', 'text')
    $(this).addClass('d-none')
    $(this).next().removeClass('d-none')
  })

  $(".hide-pass").on('click', function () {
    $(this).closest('.row').find('input').prop('type', 'password')
    $(this).addClass('d-none')
    $(this).prev().removeClass('d-none')
  })

  $("#last_name").keyup(function () {
    var last_name = $(this).val().trim()
    if (last_name) {
      checkDataContact()
      checkName(last_name, "last_name", "error_last_name")
    } else {
      $(this).addClass("is-invalid")
      $("#error_last_name").html("Last name must be from 1 to 32 characters.")
      changeBtnSave("btn_save_contact", false)
    }
  })

})

function checkDataContact() {
  var first_name = $("#first_name").val()
  var last_name = $("#last_name").val()
  var phone = $("#phone_number").val()
  if (first_name.trim() && last_name.trim() && phone.trim(0)) {
    changeBtnSave("btn_save_contact", true)
  } else {
    changeBtnSave("btn_save_contact", false)
  }
}

function changeBtnSave(btn, bool, type) {
  if (type) {
    var old_pass = $("#old_pass").val()
    var new_pass = $("#new_pass").val()
    var confirm_pass = $("#confirm_pass").val()
    if (old_pass && new_pass && confirm_pass && (new_pass == confirm_pass)) {
      $('#' + btn).attr("disabled", false);
      $('#' + btn).addClass("btn-primary").removeClass("btn-secondary")
    } else {
      $('#' + btn).attr("disabled", true);
      $('#' + btn).removeClass("btn-primary").addClass("btn-secondary")
    }
  } else {
    if (bool == true) {
      $('#' + btn).attr("disabled", false);
      $('#' + btn).addClass("btn-primary").removeClass("btn-secondary")
    } else {
      $('#' + btn).attr("disabled", true);
      $('#' + btn).removeClass("btn-primary").addClass("btn-secondary")
    }
  }
}

function changeClassStatus(item, status) {
  if (status) {
    item.addClass("is-valid").removeClass("is-invalid")
  } else {
    item.addClass("is-invalid").removeClass("is-valid")
  }
}

function checkEmptyData() {
  var status = true
  if ($("#old_pass").val() == "") {
    $("#old_pass").addClass("is-invalid")
    $("#error_old_pass").html("Please enter old password")
    status = false
  }
  if ($("#new_pass").val() == "") {
    changeClassStatus($("#new_pass"))
    $("#error_new_pass").html("Please enter new password")
    status = false
  }
  if ($("#confirm_pass").val() == "") {
    changeClassStatus($("#confirm_pass"))
    $("#error_confirm").html("Please enter confirm password")
    status = false
  }
  return status
}

function checkConfirm() {
  if ($("#new_pass").val() == $("#confirm_pass").val()) {
    changeBtnSave("btn_change_password", true)
  } else {
    changeClassStatus($("#confirm_pass"))
    changeBtnSave("btn_change_password", false)
  }
}

function checkName(input, idinput, idspan) {
  var regex = new RegExp("^[a-zA-Z_ÀÁÂÃÈÉÊÌÍÒÓÔÕÙÚĂĐĨŨƠàáâãèéêìíòóôõùúăđĩũơƯĂẠẢẤẦẨẪẬẮẰẲẴẶ" +
    "ẸẺẼỀỀỂưăạảấầẩẫậắằẳẵặẹẻẽềềểếỄỆẾỈỊỌỎỐỒỔỖỘỚỜỞỠỢỤÚỦỨỪễệỉịọỏốồổỗộớờởỡợ" +
    "ụúủứừÚỬỮỰỲỴÝỶỸửữựỳýỵỷỹ\\s]+$")
  if (!regex.test(input)) {
    $("#" + idspan).html("This field is invalid")
    $("#" + idinput).addClass("is-invalid")
    changeBtnSave("btn_save_contact", false)
  } else {
    $("#" + idspan).html("")
    $("#" + idinput).removeClass("is-invalid")
  }
}

function checkPhoneNumber(input, idinput, idspan) {
  var regex = /^[0-9\-\+]{9,12}$/
  if (!regex.test(input)) {
    $("#" + idspan).html("Must is valid phone number and maximum number is 12")
    $("#" + idinput).addClass("is-invalid")
    changeBtnSave("btn_save_contact", false)
  } else {
    $("#" + idspan).html("")
    $("#" + idinput).removeClass("is-invalid")
  }
}