defmodule Feedly.Schemas.CVE do
  @moduledoc """
  Represents CVE (Common Vulnerabilities and Exposures) metadata.
  """
  use TypedStruct

  typedstruct do
    field(:id, String.t())
    field(:label, String.t())
    field(:description, String.t())
    field(:cvss_score, float())
    field(:cvss_category_estimate, String.t())
    field(:has_exploit, boolean())
    field(:has_patch, boolean())
    field(:mentions, list(map()))
  end

  @doc """
  Parses CVE data from API response.
  """
  @spec from_api(map()) :: t()
  def from_api(data) when is_map(data) do
    vulnerability_info = data["vulnerabilityInfo"] || %{}

    %__MODULE__{
      id: data["id"],
      label: data["label"],
      description: vulnerability_info["description"],
      cvss_score: vulnerability_info["cvssScore"],
      cvss_category_estimate: vulnerability_info["cvssCategoryEstimate"],
      has_exploit: vulnerability_info["hasExploit"] || false,
      has_patch: vulnerability_info["hasPatch"] || false,
      mentions: data["mentions"] || []
    }
  end
end
