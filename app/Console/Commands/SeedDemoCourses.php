<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class SeedDemoCourses extends Command
{
    protected $signature = 'courses:seed-demo';
    protected $description = 'Seed demo approved courses for the catalog';

    public function handle()
    {
        $instructorId = DB::table('users')->min('id') ?? 1;

        $courses = [
            [
                'title' => 'Marketing Digital pour Débutants',
                'description' => 'Apprenez les bases du marketing digital : réseaux sociaux, SEO, publicité en ligne, et stratégie de contenu.',
                'category' => 'Marketing',
                'level' => 'beginner',
                'price' => 5000,
                'is_free' => false,
                'sections' => [
                    ['title' => 'Introduction au Marketing Digital', 'lessons' => [
                        ['title' => 'Qu\'est-ce que le Marketing Digital?', 'type' => 'text', 'content' => 'Le marketing digital englobe toutes les activités de marketing sur les supports numériques.', 'duration' => 600, 'is_free_preview' => 1],
                        ['title' => 'Les Réseaux Sociaux', 'type' => 'text', 'content' => 'Les réseaux sociaux sont des plateformes en ligne pour créer et partager du contenu.', 'duration' => 900, 'is_free_preview' => 1],
                    ]],
                    ['title' => 'SEO et Référencement', 'lessons' => [
                        ['title' => 'Introduction au SEO', 'type' => 'text', 'content' => 'Le SEO améliore la visibilité de votre site dans les résultats de recherche Google.', 'duration' => 720, 'is_free_preview' => 1],
                    ]],
                ],
            ],
            [
                'title' => 'Développement Web avec JavaScript',
                'description' => 'Maîtrisez JavaScript de zéro à professionnel. Créez des sites web dynamiques et interactifs.',
                'category' => 'Développement',
                'level' => 'beginner',
                'price' => 8000,
                'is_free' => false,
                'sections' => [
                    ['title' => 'Les Bases de JavaScript', 'lessons' => [
                        ['title' => 'Variables et Types', 'type' => 'text', 'content' => 'JavaScript propose var, let et const pour déclarer des variables.', 'duration' => 600, 'is_free_preview' => 1],
                        ['title' => 'Fonctions et Portée', 'type' => 'text', 'content' => 'Les fonctions sont des blocs de code réutilisables.', 'duration' => 900, 'is_free_preview' => 0],
                    ]],
                ],
            ],
            [
                'title' => 'Entrepreneuriat en RDC',
                'description' => 'Guide complet pour créer et développer votre entreprise en RDC.',
                'category' => 'Entrepreneuriat',
                'level' => 'beginner',
                'price' => 0,
                'is_free' => true,
                'sections' => [
                    ['title' => 'Lancer son Entreprise', 'lessons' => [
                        ['title' => 'Trouver une Idée', 'type' => 'text', 'content' => 'Identifiez un besoin sur le marché et proposez une solution innovante.', 'duration' => 600, 'is_free_preview' => 1],
                    ]],
                ],
            ],
            [
                'title' => 'Design Graphique avec Canva',
                'description' => 'Apprenez à créer des designs professionnels avec Canva.',
                'category' => 'Design',
                'level' => 'beginner',
                'price' => 3000,
                'is_free' => false,
                'sections' => [
                    ['title' => 'Prise en Main de Canva', 'lessons' => [
                        ['title' => 'Interface et Outils', 'type' => 'text', 'content' => 'Canva est un outil de design en ligne gratuit avec des milliers de templates.', 'duration' => 480, 'is_free_preview' => 1],
                    ]],
                ],
            ],
        ];

        $created = 0;
        foreach ($courses as $courseData) {
            $sections = $courseData['sections'] ?? [];
            unset($courseData['sections']);

            $exists = DB::table('courses')->where('title', $courseData['title'])->first();
            if ($exists) {
                $this->line("Skip (exists): {$courseData['title']}");
                continue;
            }

            $courseId = DB::table('courses')->insertGetId(array_merge($courseData, [
                'instructor_id' => $instructorId,
                'is_published' => true,
                'status' => 'approved',
                'featured' => false,
                'duration_minutes' => 0,
                'lessons_count' => 0,
                'students_count' => 0,
                'rating' => 0,
                'reviews_count' => 0,
                'created_at' => now(),
                'updated_at' => now(),
            ]));

            $totalDuration = 0;
            $totalLessons = 0;

            foreach ($sections as $sIndex => $sectionData) {
                $lessons = $sectionData['lessons'] ?? [];
                unset($sectionData['lessons']);

                $sectionId = DB::table('course_sections')->insertGetId([
                    'course_id' => $courseId,
                    'title' => $sectionData['title'],
                    'description' => $sectionData['description'] ?? null,
                    'order_position' => $sIndex + 1,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);

                foreach ($lessons as $lIndex => $lessonData) {
                    $dur = $lessonData['duration'] ?? 0;
                    DB::table('course_lessons')->insert([
                        'course_id' => $courseId,
                        'section_id' => $sectionId,
                        'title' => $lessonData['title'],
                        'description' => $lessonData['description'] ?? null,
                        'content' => $lessonData['content'] ?? null,
                        'type' => $lessonData['type'] ?? 'text',
                        'video_url' => $lessonData['video_url'] ?? null,
                        'video_duration' => $dur,
                        'documents' => null,
                        'order_position' => $lIndex + 1,
                        'is_free_preview' => $lessonData['is_free_preview'] ?? 0,
                        'is_published' => 1,
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);
                    $totalDuration += $dur;
                    $totalLessons++;
                }
            }

            DB::table('courses')->where('id', $courseId)->update([
                'duration_minutes' => (int) ($totalDuration / 60),
                'lessons_count' => $totalLessons,
            ]);

            $created++;
            $this->line("Created: {$courseData['title']} (id=$courseId, lessons=$totalLessons)");
        }

        $this->info("Done. {$created} courses created.");

        $approved = DB::table('courses')
            ->where('status', 'draft')
            ->where('is_published', false)
            ->update(['status' => 'approved', 'is_published' => true, 'updated_at' => now()]);

        if ($approved > 0) {
            $this->info("Approved {$approved} draft courses.");
        }

        return Command::SUCCESS;
    }
}
