function validate_registration(form) {
    if (form.username.value == "") {
        form.username.style.backgroundColor = "rgba(245, 106, 82, 0.41)";
        document.getElementById('error_message').innerHTML = "Please enter a username";
        return false;
    }
    else if (form.password.value == "") {
        form.password.style.backgroundColor = "rgba(245, 106, 82, 0.41)";
        document.getElementById('error_message').innerHTML = "Please enter a password";
        return false;
    }
    else if (form.rep_password.value == "") {
        form.rep_password.style.backgroundColor = "rgba(245, 106, 82, 0.41)";
        document.getElementById('error_message').innerHTML = "Please repeat your password";
        return false;
    }
    else if (form.rep_password.value != form.password.value) {
        document.getElementById('error_message').innerHTML = "Your passwords do not match";
        return false;
    }

    return true;
}

function validate_quick_add(form) {
    form.item_name.value = form.item_name.value.trim();
    if (form.item_name.value == "") {
        form.item_name.style.backgroundColor = "rgba(245, 106, 82, 0.41)";
        document.getElementById('error_message').innerHTML = "Please enter an item name";
        return false;
    }
    else if (form.item_price.value == "") {
        form.item_price.style.backgroundColor = "rgba(245, 106, 82, 0.41)";
        document.getElementById('error_message').innerHTML = "Please enter a price for the item";
        return false
    }

    return true;
}

function validate_comment(form) {
    form.item_comment.value = form.item_comment.value.trim();
    if (form.item_comment.value == "") {
        form.item_comment.style.backgroundColor = "rgba(245, 106, 82, 0.41)";
        document.getElementById('error_message').innerHTML = "Please enter something!";
        return false;
    }
    return true;
}

function validate_login(form) {
    if (form.username.value == "") {
        form.username.style.backgroundColor = "rgba(245, 106, 82, 0.41)";
        document.getElementById('error_message').innerHTML = "Please enter a username";
        return false
    }
    else if (form.password.value == "") {
        form.password.style.backgroundColor = "rgba(245, 106, 82, 0.41)";
        document.getElementById('error_message').innerHTML = "Please enter a password";
        return false;
    }

    return true;
}

function goBack() {
    window.history.back()
}

function validate_profile_edit(form) {
    if (form.password_old.value == "") {
        form.password_old.style.backgroundColor = "rgba(245, 106, 82, 0.41)";
        document.getElementById('error_message').innerHTML = "You must enter your old password";
        return false;
    }

    if (form.password_new.value != "") {
        if (form.rep_password.value == "") {
            form.rep_password.style.backgroundColor = "rgba(245, 106, 82, 0.41)";
            document.getElementById('error_message').innerHTML = "You must repeat your new password";
            return false;
        }
        if (form.rep_password.value != form.password_new.value) {
            document.getElementById('error_message').innerHTML = "Your passwords do not match";
            return false;
        }
    }
    return true;
}

function validate_item_edit(form) {
    form.item_name.value = form.item_name.value.trim();
    if (form.item_name.value == "") {
        form.item_name.style.backgroundColor = "rgba(245, 106, 82, 0.41)";
        document.getElementById('error_message').innerHTML = "Please enter an item name";
        return false;
    }
    else if (form.item_price.value == "") {
        form.item_price.style.backgroundColor = "rgba(245, 106, 82, 0.41)";
        document.getElementById('error_message').innerHTML = "Please enter a price for the item";
        return false;
    }

    return true;
}

function validate_gift_transfer(form) {
    form.gift_amount.value = form.gift_amount.value.trim();

    if (form.gift_amount.value == "") {
        form.gift_amount.style.backgroundColor = "rgba(245, 106, 82, 0.41)";
        document.getElementById('error_message').innerHTML = "Please enter amount";
        return false;
    }

    return true;
}
