%global pypi_name jc
%global desc JSON CLI output utility. JC is used to JSONify the output of many linux\
CLI tools and file-types for easier parsing in scripts.

Name:           %{pypi_name}
Version:        1.11.2
Release:        1%{?dist}
Summary:        Serialize the output of CLI tools and file-types to structured JSON

License:        MIT
URL:            https://github.com/kellyjonbrazil/jc
Source0:        %{pypi_source}
BuildArch:      noarch

BuildRequires:  python3-devel
BuildRequires:  python3dist(setuptools)
BuildRequires:  python3dist(pygments) >= 2.4.2
BuildRequires:  python3dist(ruamel.yaml) >= 0.15
BuildRequires:  python3dist(xmltodict) >= 0.12

%description
%{desc}

%prep
%autosetup -n %{pypi_name}-%{version}
rm -rf %{pypi_name}.egg-info

%build
%py3_build

%install
%py3_install

%files
%doc README.md
%license LICENSE.md
%{_bindir}/%{pypi_name}
%{python3_sitelib}/%{pypi_name}
%{python3_sitelib}/%{pypi_name}-%{version}-py%{python3_version}.egg-info

%changelog
* Tue Jun 02 2020 Kelly Brazil <kellyjonbrazil@gmail.com> - 1.11.2-1
- Initial package.
