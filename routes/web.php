<?php

use Illuminate\Support\Facades\Route;
use Meilisearch\Client;

Route::get('/', function () {
    return view('welcome');
});
Route::get('/autogen', function () {
    echo 'SELAMAT DATANG DI TOKO LPG YAUMI BACKEND OK!';
});

Route::get('/delete-all-indexes', function () {
    $client = new Client(
        config('scout.meilisearch.host'),
        config('scout.meilisearch.key')
    );


    // Ambil semua index
    $indexes = $client->getIndexes();

    // Hapus semua index
    foreach ($indexes as $index) {
        $client->deleteIndex($index->getUid());
    }

    return response()->json(['message' => 'Semua index berhasil dihapus']);
});
