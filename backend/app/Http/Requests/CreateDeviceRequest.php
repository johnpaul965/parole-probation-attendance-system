<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class CreateDeviceRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'device_id' => ['required', 'string', 'max:64', 'unique:devices,device_id'],
            'device_name' => ['nullable', 'string', 'max:128'],
            'device_type' => ['nullable', 'string', 'max:64'],
            'serial_number' => ['nullable', 'string', 'max:128'],
        ];
    }
}
