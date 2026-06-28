<?php
$db = new PDO("sqlite:c:/xampp/htdocs/lostfound/database/lostfound.db");
$db->exec("INSERT OR IGNORE INTO users (user_id, user_name, user_email, user_password) VALUES (1, 'Test', 'test@example.com', 'pass')");

$_POST['user_id'] = '1';
$_POST['report_title'] = 'Test Report';
$_POST['report_type'] = 'Lost';
$_POST['report_category'] = 'Documents';
$_POST['report_location'] = 'Test Location';
$_POST['report_description'] = 'Test Description';

$tmp = tempnam(sys_get_temp_dir(), 'img');
file_put_contents($tmp, 'test');
$_FILES['image'] = [
    'tmp_name' => $tmp,
    'name' => 'test.jpg',
    'error' => 0,
    'size' => 4,
    'type' => 'image/jpeg',
];

include 'c:/xampp/htdocs/lostfound/api/add_report.php';
unlink($tmp);
