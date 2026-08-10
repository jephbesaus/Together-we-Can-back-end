<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Campaign;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Storage;

class CampaignController extends Controller
{
    use \App\Traits\ApiResponseTrait;

    public function myCampaigns(Request $request)
    {
        $status = $request->input('status');
        $query = Campaign::forUser(auth()->id());

        if ($status === 'active') {
            $query->where('status', 'active');
        } elseif ($status === 'ended') {
            $query->where('status', 'ended');
        }

        $campaigns = $query->orderBy('created_at', 'desc')->get();

        return $this->successResponse(['campaigns' => $campaigns]);
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'title' => 'required|string|max:255',
            'description' => 'nullable|string|max:2000',
            'image' => 'nullable|file|mimes:jpeg,png,gif|max:5120',
            'link' => 'nullable|string|max:500',
            'budget' => 'required|numeric|min:0',
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date|after_or_equal:start_date',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        $user = auth()->user();
        if ($user->boost_balance < $request->budget) {
            return $this->errorResponse('Solde insuffisant pour ce budget.', 400);
        }

        $imageUrl = null;
        if ($request->hasFile('image')) {
            $path = $request->file('image')->store('campaigns', 'public');
            $imageUrl = Storage::url($path);
        }

        if ($request->budget > 0) {
            $user->decrement('boost_balance', $request->budget);
        }

        $campaign = Campaign::create([
            'user_id' => $user->id,
            'title' => $request->title,
            'description' => $request->description,
            'image_url' => $imageUrl,
            'link' => $request->link,
            'budget' => $request->budget,
            'start_date' => $request->start_date,
            'end_date' => $request->end_date,
            'status' => 'active',
        ]);

        return $this->successResponse([
            'message' => 'Campagne créée avec succès.',
            'campaign' => $campaign,
        ], 201);
    }

    public function show($id)
    {
        $campaign = Campaign::forUser(auth()->id())->find($id);

        if (!$campaign) {
            return $this->errorResponse('Campaign not found.', 404);
        }

        return $this->successResponse(['campaign' => $campaign]);
    }

    public function stats($id)
    {
        $campaign = Campaign::forUser(auth()->id())->find($id);

        if (!$campaign) {
            return $this->errorResponse('Campaign not found.', 404);
        }

        return $this->successResponse([
            'views' => $campaign->views_count,
            'clicks' => $campaign->clicks_count,
            'conversion_rate' => $campaign->views_count > 0
                ? round(($campaign->clicks_count / $campaign->views_count) * 100, 2)
                : 0,
        ]);
    }

    public function stop($id)
    {
        $campaign = Campaign::forUser(auth()->id())->find($id);

        if (!$campaign) {
            return $this->errorResponse('Campaign not found.', 404);
        }

        $campaign->update(['status' => 'ended']);

        return $this->successResponse(['message' => 'Campagne arrêtée.']);
    }
}
