<?php

namespace App\Console\Commands;

use App\Models\Post;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Storage;

class CleanupExpiredStories extends Command
{
    protected $signature = 'stories:cleanup';
    protected $description = 'Supprime les stories expirées et leurs médias';

    public function handle()
    {
        $expiredStories = Post::where('is_story', true)
            ->whereNotNull('story_expires_at')
            ->where('story_expires_at', '<', now())
            ->get();

        $deleted = 0;

        foreach ($expiredStories as $story) {
            if ($story->media_url) {
                $mediaUrls = json_decode($story->media_url, true) ?? [$story->media_url];
                foreach ($mediaUrls as $url) {
                    $path = str_replace('/storage/', 'public/', $url);
                    Storage::delete($path);
                }
            }

            $story->delete();
            $deleted++;
        }

        $this->info("$deleted story(ies) expirée(s) supprimée(s).");

        return 0;
    }
}
