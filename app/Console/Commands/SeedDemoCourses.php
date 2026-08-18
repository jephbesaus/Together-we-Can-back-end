<?php

namespace App\Console\Commands;

use App\Models\Course;
use App\Models\CourseSection;
use App\Models\CourseLesson;
use Illuminate\Console\Command;

class SeedDemoCourses extends Command
{
    protected $signature = 'courses:seed-demo';
    protected $description = 'Seed demo approved courses for the catalog';

    public function handle()
    {
        $courses = [
            [
                'title' => 'Marketing Digital pour Débutants',
                'description' => 'Apprenez les bases du marketing digital : réseaux sociaux, SEO, publicité en ligne, et stratégie de contenu. Ce cours complet vous donnera toutes les clés pour lancer votre présence en ligne.',
                'category' => 'Marketing',
                'level' => 'beginner',
                'price' => 5000,
                'is_free' => false,
                'is_published' => true,
                'status' => 'approved',
                'duration_minutes' => 120,
                'what_you_will_learn' => ['Maîtriser les réseaux sociaux', 'Créer une stratégie de contenu', 'Comprendre le SEO', 'Lancer des publicités en ligne'],
                'requirements' => ['Aucun prérequis', 'Une connexion internet'],
                'target_audience' => ['Débutants en marketing digital', 'Entrepreneurs', 'Créateurs de contenu'],
                'sections' => [
                    ['title' => 'Introduction au Marketing Digital', 'lessons' => [
                        ['title' => 'Qu\'est-ce que le Marketing Digital?', 'type' => 'text', 'content' => 'Le marketing digital englobe toutes les activités de marketing sur les supports numériques. C\'est un ensemble de techniques et de stratégies qui permettent de promouvoir une marque, un produit ou un service via les canaux numériques.', 'duration' => 600, 'is_free_preview' => true],
                        ['title' => 'Les Réseaux Sociaux', 'type' => 'text', 'content' => 'Les réseaux sociaux sont des plateformes en ligne qui permettent aux utilisateurs de créer du contenu, de le partager et d\'interagir avec d\'autres utilisateurs. Facebook, Instagram, TikTok et LinkedIn sont les plus populaires en RDC.', 'duration' => 900, 'is_free_preview' => true],
                        ['title' => 'Créer son Identité Numérique', 'type' => 'text', 'content' => 'L\'identité numérique est l\'ensemble des informations disponibles en ligne sur une personne ou une entreprise. Elle comprend votre nom, vos photos, vos publications et votre réputation en ligne.', 'duration' => 600, 'is_free_preview' => false],
                    ]],
                    ['title' => 'SEO et Référencement', 'lessons' => [
                        ['title' => 'Introduction au SEO', 'type' => 'text', 'content' => 'Le SEO (Search Engine Optimization) est l\'ensemble des techniques qui permettent d\'améliorer la visibilité d\'un site web dans les résultats de recherche naturels de Google.', 'duration' => 720, 'is_free_preview' => true],
                        ['title' => 'Mots-clés et Recherche', 'type' => 'text', 'content' => 'La recherche de mots-clés est la première étape du SEO. Il faut identifier les termes que votre public cible utilise pour chercher vos produits ou services.', 'duration' => 600, 'is_free_preview' => false],
                    ]],
                    ['title' => 'Publicité en Ligne', 'lessons' => [
                        ['title' => 'Facebook & Instagram Ads', 'type' => 'text', 'content' => 'Facebook et Instagram Ads vous permettent de cibler précisément votre audience selon l\'âge, la localisation, les centres d\'intérêt et bien plus.', 'duration' => 900, 'is_free_preview' => true],
                        ['title' => 'Budget et ROI', 'type' => 'text', 'content' => 'Apprenez à optimiser votre budget publicitaire et à mesurer le retour sur investissement de vos campagnes.', 'duration' => 600, 'is_free_preview' => false],
                    ]],
                ],
            ],
            [
                'title' => 'Développement Web avec JavaScript',
                'description' => 'Maîtrisez JavaScript de zéro à professionnel. Apprenez à créer des sites web dynamiques et interactifs avec le langage le plus utilisé au monde.',
                'category' => 'Développement',
                'level' => 'beginner',
                'price' => 8000,
                'is_free' => false,
                'is_published' => true,
                'status' => 'approved',
                'duration_minutes' => 240,
                'what_you_will_learn' => ['Maîtriser JavaScript', 'Créer des sites web dynamiques', 'Manipuler le DOM', 'Travailler avec les API'],
                'requirements' => ['Connaissances de base en HTML/CSS', 'Un ordinateur avec un navigateur web'],
                'target_audience' => ['Développeurs débutants', 'Étudiants', 'Personnes souhaitant changer de carrière'],
                'sections' => [
                    ['title' => 'Les Bases de JavaScript', 'lessons' => [
                        ['title' => 'Variables et Types de Données', 'type' => 'text', 'content' => 'JavaScript propose trois mots-clés pour déclarer des variables : var, let et const. Les types de données incluent les chaînes de caractères, les nombres, les booléens, les tableaux et les objets.', 'duration' => 600, 'is_free_preview' => true],
                        ['title' => 'Fonctions et Portée', 'type' => 'text', 'content' => 'Les fonctions sont des blocs de code réutilisables. En JavaScript, on peut les déclarer avec function ou les assigner à des variables (fonctions fléchées).', 'duration' => 900, 'is_free_preview' => false],
                    ]],
                    ['title' => 'DOM et Événements', 'lessons' => [
                        ['title' => 'Manipulation du DOM', 'type' => 'text', 'content' => 'Le DOM (Document Object Model) est une représentation en arbre du document HTML. JavaScript peut modifier le DOM pour créer des interfaces dynamiques.', 'duration' => 720, 'is_free_preview' => true],
                    ]],
                ],
            ],
            [
                'title' => 'Entrepreneuriat en RDC',
                'description' => 'Guide complet pour créer et développer votre entreprise en République Démocratique du Congo. Stratégies, financement et conseils pratiques.',
                'category' => 'Entrepreneuriat',
                'level' => 'beginner',
                'price' => 0,
                'is_free' => true,
                'is_published' => true,
                'status' => 'approved',
                'duration_minutes' => 90,
                'what_you_will_learn' => ['Créer une entreprise en RDC', 'Trouver du financement', 'Gérer sa trésorerie', 'Développer son réseau'],
                'requirements' => ['Aucun prérequis'],
                'target_audience' => ['Aspirants entrepreneurs', 'Jeunes Congolais', 'Toute personne souhaitant créer une activité'],
                'sections' => [
                    ['title' => 'Lancer son Entreprise', 'lessons' => [
                        ['title' => 'Trouver une Idée', 'type' => 'text', 'content' => 'La première étape est d\'identifier un besoin sur le marché. Observez votre environnement, écoutez les problèmes des gens et proposez des solutions innovantes.', 'duration' => 600, 'is_free_preview' => true],
                        ['title' => 'Étude de Marché', 'type' => 'text', 'content' => 'Une étude de marché consiste à analyser l\'offre et la demande dans un secteur donné. Elle vous aide à comprendre votre concurrence et à définir votre stratégie.', 'duration' => 600, 'is_free_preview' => true],
                    ]],
                ],
            ],
            [
                'title' => 'Design Graphique avec Canva',
                'description' => 'Apprenez à créer des designs professionnels avec Canva, même sans expérience préalable. Logo, affiches, publications réseaux sociaux et plus.',
                'category' => 'Design',
                'level' => 'beginner',
                'price' => 3000,
                'is_free' => false,
                'is_published' => true,
                'status' => 'approved',
                'duration_minutes' => 60,
                'what_you_will_learn' => ['Utiliser Canva comme un pro', 'Créer des logos', 'Designer pour les réseaux sociaux', 'Créer des supports marketing'],
                'requirements' => ['Un compte Canva (gratuit)', 'Une connexion internet'],
                'target_audience' => ['Débutants en design', 'Créateurs de contenu', 'Entrepreneurs'],
                'sections' => [
                    ['title' => 'Prise en Main de Canva', 'lessons' => [
                        ['title' => 'Interface et Outils', 'type' => 'text', 'content' => 'Canva est un outil de design en ligne gratuit. Son interface intuitive propose des milliers de templates, d\'éléments graphiques et de polices.', 'duration' => 480, 'is_free_preview' => true],
                        ['title' => 'Créer un Logo', 'type' => 'text', 'content' => 'Un logo est l\'identité visuelle de votre marque. Avec Canva, vous pouvez créer un logo professionnel en quelques minutes grâce aux templates personnalisables.', 'duration' => 360, 'is_free_preview' => false],
                    ]],
                ],
            ],
        ];

        $created = 0;
        foreach ($courses as $courseData) {
            $sections = $courseData['sections'] ?? [];
            unset($courseData['sections']);

            $existing = Course::where('title', $courseData['title'])->first();
            if ($existing) {
                $this->line("Course already exists: {$courseData['title']}");
                continue;
            }

            $course = Course::create(array_merge($courseData, [
                'instructor_id' => 1,
            ]));

            foreach ($sections as $sIndex => $sectionData) {
                $lessons = $sectionData['lessons'] ?? [];
                unset($sectionData['lessons']);

                $section = CourseSection::create(array_merge($sectionData, [
                    'course_id' => $course->id,
                    'order_position' => $sIndex + 1,
                ]));

                foreach ($lessons as $lIndex => $lessonData) {
                    CourseLesson::create(array_merge($lessonData, [
                        'course_id' => $course->id,
                        'section_id' => $section->id,
                        'order_position' => $lIndex + 1,
                        'is_published' => true,
                    ]));
                }
            }

            $totalDuration = $course->sections()->with('lessons')->get()->sum(function ($s) {
                return $s->lessons->sum('video_duration');
            });
            $course->update([
                'duration_minutes' => (int) ($totalDuration / 60),
                'lessons_count' => $course->sections()->with('lessons')->get()->sum(fn($s) => $s->lessons->count()),
            ]);

            $created++;
            $this->line("Created: {$course->title} ({$course->status})");
        }

        $this->info("Done. {$created} courses created.");
        return Command::SUCCESS;
    }
}
